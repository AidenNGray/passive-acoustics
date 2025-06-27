from pydub import AudioSegment
from datetime import datetime, timedelta
import os

def get_start_time_from_log(log_file):
    """
    Extract Unix timestamp from the first line of a log file.
    Assumes format: timestamp,other_data
    
    Args:
        log_file (str): Path to the log file
        
    Returns:
        datetime: Parsed start time
    """
    try:
        with open(log_file, 'r') as f:
            first_line = f.readline().strip()
            # Extract timestamp before the first comma
            unix_timestamp = first_line.split(',')[0]
            # Convert to datetime
            start_time = datetime.fromtimestamp(int(unix_timestamp))
            return start_time
    except (FileNotFoundError, ValueError, IndexError) as e:
        print(f"Error reading start time from log file: {e}")
        return None

def split_wav_by_time(input_file, log_file, seg_length = 12, output_dir="segments"):
    """
    Split a WAV file into segments based on time boundaries.
    Start time is read from the first line of a log file (Unix timestamp).
    
    Args:
        input_file (str): Path to the input WAV file
        log_file (str): Path to the log file containing Unix timestamp
        output_dir (str): Directory to save the segments
    """
    
    # Get start time from log file
    start_time = get_start_time_from_log(log_file)
    if start_time is None:
        return
    
    print(f"Start time from log: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Load the audio file
    print(f"Loading {input_file}...")
    audio = AudioSegment.from_wav(input_file)
    total_duration_ms = len(audio)
    total_duration_hours = total_duration_ms / (1000 * 60 * 60)
    
    print(f"Total audio duration: {total_duration_hours:.2f} hours")
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Calculate segments
    segments = []
    current_time = start_time
    current_pos_ms = 0
    
    # First segment: from start time to next midnight
    next_midnight = (current_time + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
    first_segment_duration = next_midnight - current_time
    first_segment_ms = int(first_segment_duration.total_seconds() * 1000)
    
    # Make sure we don't exceed the audio length
    first_segment_ms = min(first_segment_ms, total_duration_ms)
    
    segments.append({
        'start_time': current_time,
        'start_ms': current_pos_ms,
        'end_ms': first_segment_ms,
        'duration_ms': first_segment_ms
    })
    
    current_pos_ms = first_segment_ms
    current_time = next_midnight
    
    # 12-hour segments
    twelve_hours_ms = seg_length * 60 * 60 * 1000
    
    while current_pos_ms < total_duration_ms:
        remaining_ms = total_duration_ms - current_pos_ms
        segment_duration_ms = min(twelve_hours_ms, remaining_ms)
        
        segments.append({
            'start_time': current_time,
            'start_ms': current_pos_ms,
            'end_ms': current_pos_ms + segment_duration_ms,
            'duration_ms': segment_duration_ms
        })
        
        current_pos_ms += segment_duration_ms
        current_time += timedelta(hours=12)
    
    # Export segments
    print(f"\nCreating {len(segments)} segments...")
    
    for i, segment in enumerate(segments):
        # Create filename based on start time
        filename = segment['start_time'].strftime("%Y%m%d_%H%M%S") + ".wav"
        output_path = os.path.join(output_dir, filename)
        
        # Extract audio segment
        audio_segment = audio[segment['start_ms']:segment['end_ms']]
        
        # Export
        print(f"Exporting segment {i+1}/{len(segments)}: {filename}")
        print(f"  Start time: {segment['start_time'].strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"  Duration: {segment['duration_ms'] / (1000 * 60 * 60):.2f} hours")
        
        audio_segment.export(output_path, format="wav")
    
    print(f"\nAll segments saved to '{output_dir}' directory")

# Example usage
if __name__ == "__main__":
    # Read start time from log file and split WAV
    base_file_name = "angus_whale_2024_03_18"
    audio_dir = "tools/dtg processing/audio/"
    log_dir = "tools/dtg processing/logs/"
    segment_length = 12 # hours
    output_dir = "tools/dtg processing/" + base_file_name + " - " + str(segment_length) + " Hour Segments"
    

    file_count = len([f for f in os.listdir(audio_dir) if os.path.isfile(os.path.join(audio_dir, f))])
    for fileNum in range(file_count):
        input_wav = audio_dir + base_file_name + f"{fileNum+1:03}" + ".wav"  
        log_file = log_dir + base_file_name + f"{fileNum+1:03}" + ".log"         
        
        split_wav_by_time(input_wav, log_file, segment_length, output_dir)
    
    # You can also specify a custom output directory
    # split_wav_by_time("large_recording.wav", "recording.log", "my_segments")