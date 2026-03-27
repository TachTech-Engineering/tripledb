  1. Actual Audio Files on Disk by Extension
  There are indeed 778 MP3 files successfully downloaded, confirming the Group B runner's success count.
   * 779 .info.json
   * 778 .mp3
   * 1 .webm
   * 1 .part (incomplete download)
   * 1 .csv (manifest)
   * 1 .gitkeep


  2. MP3 vs Other Formats
   * .mp3: 778
   * .webm: 1
   * .m4a / .opus: 0


  3. Recent Audio Files
  The data/audio/ directory contains typical files like:
   * UFnBw6DD3Tw.mp4.part (partial download from a failed attempt)
   * manifest.csv
   * Paired <video_id>.mp3 and <video_id>.info.json files (e.g., q9-KBbLDDfk.mp3).


  4. How phase2_transcribe.py Finds Audio Files
  The script reads video_id from the manifest and constructs the path via basic string concatenation without stripping whitespace:


   1 mp3_path = f"data/audio/{video_id}.mp3"
   2 if not os.path.exists(mp3_path):
   3     print(f"Warning: Missing audio for {video_id} ({idx}/{total_videos}), skipping.")


  5. The Manifest File (data/audio/manifest.csv)
  Inspecting the manifest reveals that the video_id column contains trailing spaces. For example:


   1 BwfqvpCAdeQ  ,,,https://www.youtube.com/watch?v=BwfqvpCAdeQ...
   2 ILVeTE6416Q  ,,,https://...
  (Notice the two spaces after the 11-character video ID).


  6. Transcripts vs Audio Files
  There are currently 123 .json transcripts in data/transcripts/.


  7. yt-dlp Output Format
  Running file on the disk contents confirms yt-dlp is properly converting and saving the audio as valid MP3 files:


   1 data/audio/0AtBcVwss10.mp3: Audio file with ID3 version 2.4.0, contains: MPEG ADTS, layer III, v1, variable bitrate, 48 kHz, Stereo

  ---


  🚨 Root Cause
  The video_id column in data/audio/manifest.csv contains trailing whitespaces (e.g., "BwfqvpCAdeQ  ").


  Because scripts/phase2_transcribe.py extracts the video_id directly from the CSV dict without calling .strip(), it attempts to look up
  the file at data/audio/BwfqvpCAdeQ  .mp3 instead of data/audio/BwfqvpCAdeQ.mp3. The file is correctly named on disk without the spaces,
  causing os.path.exists() to fail and the script to erroneously report "Missing audio" for all 778 downloaded files.
