es 🥞 | Diners, Drive-Ins and Dives | Food Network [22:55]
https://www.youtube.com/watch?v=MtaEkTqSEDY  # Top #DDD Chinese Food Videos with Guy Fieri | Diners, Drive-Ins and Dives | Food Network [17:55]
https://www.youtube.com/watch?v=n-g_g_Ye9Pk  # Top #DDD Videos in Portland with Guy Fieri 🌟 | Diners, Drive-Ins, and Dives | Food Network [14:55]
https://www.youtube.com/watch?v=9_IJBYW4vWM  # Top #DDD Mediterranean Videos with Guy Fieri | Diners, Drive-Ins and Dives [23:07]
https://www.youtube.com/watch?v=3Tsj8yHFeZU  # Guy Fieri Devours Massive Corned Beef in San Francisco 🍖| Diners, Drive-Ins and Dives | Food Network [27:00]
https://www.youtube.com/watch?v=SDxziQtijtM  # Top #DDD Videos in Minneapolis with Guy Fieri | Diners, Drive-Ins, and Dives | Food Network [20:26]
https://www.youtube.com/watch?v=-DD4PEUheLU  # Top #DDD RAMEN Videos with Guy Fieri 🍜 | Diners, Drive-Ins and Dives | Food Network [30:50]
https://www.youtube.com/watch?v=es-lcpqknPE  # Guy Fieri Tries LEGENDARY Oyster Loaf in New Orleans 🔥| Diners, Drive-Ins and Dives | Food Network [17:31]
https://www.youtube.com/watch?v=FJPfjAmgbjQ  # Top #DDD Dip Videos with Guy Fieri | Diners, Drive-Ins and Dives | Food Network [14:32]
https://www.youtube.com/watch?v=vLWFRNY10ww  # Guy Fieri Devours Pittsburgh Pasta 🍝 | Diners, Drive-Ins and Dives | Food Network [12:28]
https://www.youtube.com/watch?v=XCHQ732SECo  # Guy Fieri Eats the 15-INCH Homewrecker Hot Dog at Hillbilly Hotdogs 🌭 | Diners, Drive-Ins & Dives [15:51]
https://www.youtube.com/watch?v=HGdeCh12MpU  # Top #DDD Bacon, Sausage & Ham Videos with Guy Fieri [32:32]
https://www.youtube.com/watch?v=7II3tnaCdvk  # Wait, They Put WHAT In That?! Top 10 Times Guy Fieri Was Shocked on #DDD 😱 | Food Network [19:21]
https://www.youtube.com/watch?v=KNWxHQXWWbk  # BINGE the Best of #DDD Season 7 with Guy Fieri 🔥 | Food Network [1:06:44]
https://www.youtube.com/watch?v=r8OqkxuHO5Y  # Guy Fieri Digs Into Massive BBQ Plates in Portland 🍖 | Diners, Drive-Ins and Dives | Food Network [22:02]
https://www.youtube.com/watch?v=5sMtashu7IM  # #DDD Road Trip: Guy Fieri Takes the Great Lakes 🚗 | Diners, Drive-Ins, and Dives | Food Network [27:26]

~/dev/projects/tripledb/pipeline main*
❯ cd config/

~/dev/projects/tripledb/pipeline/config main*
❯ nano test_batch.txt

~/dev/projects/tripledb/pipeline/config main* 1m 15s
❯ cd ..

~/dev/projects/tripledb/pipeline main*
❯ cd ..

~/dev/projects/tripledb main*
❯ cd docs

~/dev/projects/tripledb/docs main*
❯ ls
drwxr-xr-x   - kthompson 20 Mar 14:41  archive
.rw-r--r-- 35k kthompson 19 Mar 23:09  ddd-design-architecture-v6.md
.rw-r--r-- 15k kthompson 19 Mar 23:09  ddd-phase-prompts-v6.md
.rw-r--r-- 17k kthompson 20 Mar 14:40  ddd-plan-v1.8.md
.rw-r--r-- 21k kthompson 19 Mar 23:09  ddd-project-setup-v6.md

~/dev/projects/tripledb/docs main*
❯ cd ..

~/dev/projects/tripledb main*
❯ cd pipeline/

~/dev/projects/tripledb/pipeline main*
❯ python3 scripts/phase1_acquire.py --batch config/test_batch.txt
Downloading 1/30: BwfqvpCAdeQ  ... failed [3.1s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['us1REiIyQ1SZu2JS', '5YPgTy5NyDPrPp-E', 'uUQvGqWBX51YFOga', 'LJhXsfaIGhDmc7Bl'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] BwfqvpCAdeQ: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] BwfqvpCAdeQ: Requested format is not available. Use --list-formats for a list of available formats
Downloading 2/30: ILVeTE6416Q  ... failed [3.2s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['u78YYB1FQJ9cxZ8C', 'pjLKVqRAdDQm6aEN', 'KeUY8gvqYJKxFa9F', 'CENDsAsiklAa7mcb'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] ILVeTE6416Q: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] ILVeTE6416Q: Requested format is not available. Use --list-formats for a list of available formats
Downloading 3/30: vLWFRNY10ww  ... failed [2.5s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['bjALTcQxIfEjJJq0', 'IMxcQqmmo51DwtzI', '96oFIYfH0pcS7a5S', 'TujH3_b3SfZDfv-W'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] vLWFRNY10ww: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] vLWFRNY10ww: Requested format is not available. Use --list-formats for a list of available formats
Downloading 4/30: Dcfs_wKVi9A  ... failed [2.8s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['GMfwuxf9s9P9Iv17', 'LzYxV3uBFjYJ3-OR', 'JkhuLubcpvME8ZOX', 'fOExl3kr_jXkY4EY'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] Dcfs_wKVi9A: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] Dcfs_wKVi9A: Requested format is not available. Use --list-formats for a list of available formats
Downloading 5/30: CFSLE4rFbPI  ... failed [2.4s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['DVLigjyTzxQvGreo', 'hu9ZVBRKhj8It_1s', '_8HDDVHG8zJ_aJVe', 'BACCaYO6ARWp0v6m'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] CFSLE4rFbPI: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] CFSLE4rFbPI: Requested format is not available. Use --list-formats for a list of available formats
Downloading 6/30: 8f7oydDMu1c  ... failed [2.5s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['Z14p64s9WlfWIv9n', '353ODnzdtjy6gg_h', '0WT63-eqQ_g32ELb', 'Sa1A60BA9BG0KrJi'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] 8f7oydDMu1c: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] 8f7oydDMu1c: Requested format is not available. Use --list-formats for a list of available formats
Downloading 7/30: SDxziQtijtM  ... failed [2.6s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['MZbjl0uvh7wnfbEx', '9mJblG8C8rtkiiaD', 'nI-ABMQQtXqNoAZo', 'KT8FzcNwZHO_-rN0'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] SDxziQtijtM: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] SDxziQtijtM: Requested format is not available. Use --list-formats for a list of available formats
Downloading 8/30: 5FlI4pCEnbA  ... failed [2.8s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['RRKvg2jsGhXWhhSH', 'kmI1SuZapBZ4hpjB', '44bDu0HM4p4TJ7mY', 'CxXfXIOV5Xr_3xev'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] 5FlI4pCEnbA: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] 5FlI4pCEnbA: Requested format is not available. Use --list-formats for a list of available formats
Downloading 9/30: ZWwwmcow64Q  ... failed [2.6s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['Ee3EegFmWRPQHbwD', 'mnltTQaPMfh87fJL', '_Uw2ejvT8RbnW4t2', 'Va5Pq2r5WhYWQIDC'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] ZWwwmcow64Q: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] ZWwwmcow64Q: Requested format is not available. Use --list-formats for a list of available formats
Downloading 10/30: r8OqkxuHO5Y  ... failed [2.5s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['9Q-s38Skk7MhUXzi', 'cqAYgZYSmhvfae-r', 'd4Wu2mCOI5GFTHNa', 'X1KmO1u751J0jCZv'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] r8OqkxuHO5Y: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] r8OqkxuHO5Y: Requested format is not available. Use --list-formats for a list of available formats
Downloading 11/30: otZTFDdvnrU  ... failed [2.5s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['VMICmy9M79f2vRx4', '1OwUC0LSud67pDHc', 'iliK39SLF7mKECp9', 'hKDIfYRDyv1l7d8w'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] otZTFDdvnrU: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] otZTFDdvnrU: Requested format is not available. Use --list-formats for a list of available formats
Downloading 12/30: eut9zhDgvIk  ... failed [2.4s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['wuvvvz24EXCCEX2c', 'j-8USe3WmB8si-YQ', 'THwUPa2zbXYEKOc0', 'wIDuzBLA2fl0BhHn'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] eut9zhDgvIk: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] eut9zhDgvIk: Requested format is not available. Use --list-formats for a list of available formats
Downloading 13/30: 9_IJBYW4vWM  ... failed [2.7s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['_Ghsurqa8lI9oq1R', '2hffFQ-cs3mCKVbN', '4FzpMmkl-RdU6z0N', 'eYslxTZ4KDhStKcs'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] 9_IJBYW4vWM: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] 9_IJBYW4vWM: Requested format is not available. Use --list-formats for a list of available formats
Downloading 14/30: 2Y4A0FQVhEU  ... failed [2.7s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['BR8cOvIhX54olMZT', 'f_tsfNjCuzqOFtiN', 'Myc5vlJW6_ZWOPQo', 'U6x-F3v96nwSqCHm'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] 2Y4A0FQVhEU: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] 2Y4A0FQVhEU: Requested format is not available. Use --list-formats for a list of available formats
Downloading 15/30: V3QCLF3uju8  ... failed [2.7s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['r8PSHGzeu7W4mqda', 'Wp3bNQkm73aWmfTd', 'Qmcrmnm789h8zjvo', 'yG2zGynXepn7wnZl'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] V3QCLF3uju8: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] V3QCLF3uju8: Requested format is not available. Use --list-formats for a list of available formats
Downloading 16/30: 8n8C91eU1Os  ... failed [2.5s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['45hoKIbMEB_2tRxm', 'vG_hcmGi-t9-_h8e', 'wuyW49cr2RSEcc6J', 'F77y2J3cw9y9Jlds'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] 8n8C91eU1Os: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] 8n8C91eU1Os: Requested format is not available. Use --list-formats for a list of available formats
Downloading 17/30: 9lgi73X4oGU  ... failed [2.6s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['FL-m7QcP4n-Nlh6V', 'VG9m0LOL9J2CptXq', 'eB5EaMjibRJIDCrn', 'y1amcIZnOp5ABeG8'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] 9lgi73X4oGU: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] 9lgi73X4oGU: Requested format is not available. Use --list-formats for a list of available formats
Downloading 18/30: Uh9XZtFYDK0  ... failed [3.0s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['C2vHa2Sjzl45uw9H', 'B4D0Vvuh9HY7LcNA', 'vs6td-x2AP-ZtACH', 'axMMSQUTddOxz-cs'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] Uh9XZtFYDK0: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] Uh9XZtFYDK0: Requested format is not available. Use --list-formats for a list of available formats
Downloading 19/30: fqi0tOGh7r0  ... failed [3.1s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['SUXXZ12Y-LVsWkkp', 'PctkW0_1WFiH6-VV', 'Gyv751cnD3_Fyy-d', 'bcwQBrw_3brL6e15'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] fqi0tOGh7r0: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] fqi0tOGh7r0: Requested format is not available. Use --list-formats for a list of available formats
Downloading 20/30: 3Tsj8yHFeZU  ... failed [2.6s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['ngtug4Ddm1umMhQM', 'NSqkFpJtPDvHk3XH', 'ZG3EzwBSyvjZGB5F', 'StSyaerTaJfewkoY'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] 3Tsj8yHFeZU: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] 3Tsj8yHFeZU: Requested format is not available. Use --list-formats for a list of available formats
Downloading 21/30: 5sMtashu7IM  ... failed [2.7s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['2O6cNWSgFHd6ihED', 'A_nFuDThHVyVrZ05', 'D4iZknFZ5pyzHgg4', 'iIY3PVVQv3sJmYDf'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] 5sMtashu7IM: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] 5sMtashu7IM: Requested format is not available. Use --list-formats for a list of available formats
Downloading 22/30: -DD4PEUheLU  ... failed [2.6s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['TO9PhxrEfzkwJDM-', 'R5lWQJ60fZ_gnXUQ', 'IlT2W8D4b19Yotph', 'wLC6M55EsFElVGt1'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] -DD4PEUheLU: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] -DD4PEUheLU: Requested format is not available. Use --list-formats for a list of available formats
Downloading 23/30: HGdeCh12MpU  ... failed [2.5s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['MR3HZNxB77LAf8xR', 'pXXOxpOSzL8viem6', 'jeiu2T2-Cdc4qa-8', 'pBRaYUYiy53YO32g'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] HGdeCh12MpU: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] HGdeCh12MpU: Requested format is not available. Use --list-formats for a list of available formats
Downloading 24/30: 5bRC4Oq8En8  ... failed [2.7s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['gnaACWQ_1ZatGcEb', 'Npqnmhia9t8cg2AJ', '0Hpnbkj0WrQDCYqu', 'y3fjYBIvSpABQIpf'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] 5bRC4Oq8En8: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] 5bRC4Oq8En8: Requested format is not available. Use --list-formats for a list of available formats
Downloading 25/30: ExK9OxyaPJg  ... failed [2.6s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['BAdTBXuHFfVrldi9', 'bNox_cDRvjw5Ypc0', 'mel3bE3tNnVpHUun', 'ey7YxlgXjDB4SPsI'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] ExK9OxyaPJg: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] ExK9OxyaPJg: Requested format is not available. Use --list-formats for a list of available formats
Downloading 26/30: CgPqS91kAWo  ... failed [2.9s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['rKJb9DYHRHZfItDa', '4QIzXNkvnn8WOzyD', 'JLodeD0scxwKXvOd', 'fc-H7WAvaH8oLYWb'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] CgPqS91kAWo: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] CgPqS91kAWo: Requested format is not available. Use --list-formats for a list of available formats
Downloading 27/30: TiYNdk28WxA  ... failed [2.7s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['YLVIfDLKIbR2CrZT', 'pII2FV_ZcjeD7EXg', '7uzbHDgX_nWMCoaT', 'yqixTEimQv6_E4mP'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] TiYNdk28WxA: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] TiYNdk28WxA: Requested format is not available. Use --list-formats for a list of available formats
Downloading 28/30: _GwN6SiRpzE  ... failed [2.6s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['IXlidx3G5rDF4H1m', '2StyW8HzWlZpcGOy', 'usf1O49WRJyWH-OW', 'fcOkV5mmAHwgP4eg'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] _GwN6SiRpzE: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] _GwN6SiRpzE: Requested format is not available. Use --list-formats for a list of available formats
Downloading 29/30: ZKv4Uf8Bt0g  ... failed [2.6s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['0Kl5YrtbDJHup-Ft', 'A4_3H1bIIHRpcF-7', 'Wh_zyHOnyNGAhhSg', '_AsGhYev1zNb7IX_'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] ZKv4Uf8Bt0g: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] ZKv4Uf8Bt0g: Requested format is not available. Use --list-formats for a list of available formats
Downloading 30/30: bawGcAsAA-w  ... failed [2.6s]
  Error: WARNING: [youtube] [jsc] Error solving n challenge request using "deno" provider: Error running deno process (returncode: 1): error: Uncaught (in promise) TypeError: Cannot read properties of undefined (reading 'origin')
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:22962:27)
    at eval (eval at <anonymous> (file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6208), <anonymous>:89615:4)
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6229
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:58:6235
    at file:///home/kthompson/dev/projects/tripledb/pipeline/$deno$stdin.js:59:36.
         input = NChallengeInput(player_url='https://www.youtube.com/s/player/1ebf2aa6/tv-player-ias.vflset/tv-player-ias.js', challenges=['HRmRQomKNZHGl77B', 'USlzY6erOZZDzB2l', 'RszFqhZmf1hyajWX', 'QRHLu5Q_ApxyvZDc'])
         Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
WARNING: [youtube] bawGcAsAA-w: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] bawGcAsAA-w: Requested format is not available. Use --list-formats for a list of available formats

--- Download Summary ---
Total urls: 30
Success:    0
Skipped:    0
Failed:     30

~/dev/projects/tripledb/pipeline main* 1m 20s
❯ pip install --upgrade yt-dlp --break-system-packages
  yt-dlp --version
Defaulting to user installation because normal site-packages is not writeable
Requirement already satisfied: yt-dlp in /usr/lib/python3.14/site-packages (2026.3.13)
Collecting yt-dlp
  Downloading yt_dlp-2026.3.17-py3-none-any.whl.metadata (182 kB)
Downloading yt_dlp-2026.3.17-py3-none-any.whl (3.3 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 3.3/3.3 MB 37.4 MB/s  0:00:00
Installing collected packages: yt-dlp
Successfully installed yt-dlp-2026.3.17
2026.03.17

~/dev/projects/tripledb/pipeline main*
❯ yt-dlp --cookies-from-browser chrome -x --audio-format mp3 --audio-quality 0 \
        "https://www.youtube.com/watch?v=fqi0tOGh7r0" -o "test.mp3"
Extracting cookies from chrome
Extracted 151 cookies from chrome
[youtube] Extracting URL: https://www.youtube.com/watch?v=fqi0tOGh7r0
[youtube] fqi0tOGh7r0: Downloading webpage
[youtube] fqi0tOGh7r0: Downloading tv downgraded player API JSON
[youtube] fqi0tOGh7r0: Downloading player 1ebf2aa6-main
[youtube] [jsc:deno] Solving JS challenges using deno
WARNING: [youtube] [jsc:deno] Challenge solver lib script version 0.7.0 is not supported (source: python package, variant: ScriptVariant.MINIFIED, supported version: 0.8.0)
WARNING: [youtube] [jsc] Remote components challenge solver script (deno) and NPM package (deno) were skipped. These may be required to solve JS challenges. You can enable these downloads with  --remote-components ejs:github  (recommended) or  --remote-components ejs:npm , respectively. For more information and alternatives, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: [youtube] fqi0tOGh7r0: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
WARNING: Only images are available for download. use --list-formats to see them
ERROR: [youtube] fqi0tOGh7r0: Requested format is not available. Use --list-formats for a list of available formats

~/dev/projects/tripledb/pipeline main*
❯ yt-dlp --cookies-from-browser chrome --remote-components ejs:github \
        -x --audio-format mp3 --audio-quality 0 \
        "https://www.youtube.com/watch?v=fqi0tOGh7r0" -o "test.mp3"
Extracting cookies from chrome
Extracted 149 cookies from chrome
[youtube] Extracting URL: https://www.youtube.com/watch?v=fqi0tOGh7r0
[youtube] fqi0tOGh7r0: Downloading webpage
[youtube] fqi0tOGh7r0: Downloading tv downgraded player API JSON
[youtube] fqi0tOGh7r0: Downloading player 1ebf2aa6-main
[youtube] [jsc:deno] Solving JS challenges using deno
WARNING: [youtube] [jsc:deno] Challenge solver lib script version 0.7.0 is not supported (source: python package, variant: ScriptVariant.MINIFIED, supported version: 0.8.0)
[youtube] [jsc:deno] Downloading challenge solver lib script from  https://github.com/yt-dlp/ejs/releases/download/0.8.0/yt.solver.lib.min.js
WARNING: [youtube] [jsc:deno] Challenge solver core script version 0.7.0 is not supported (source: python package, variant: ScriptVariant.MINIFIED, supported version: 0.8.0)
[youtube] fqi0tOGh7r0: Downloading m3u8 information
[info] fqi0tOGh7r0: Downloading 1 format(s): 251
[download] Destination: test.webm
[download] 100% of   20.36MiB in 00:00:00 at 30.67MiB/s
[ExtractAudio] Destination: test.mp3
Deleting original file test.webm (pass -k to keep)

~/dev/projects/tripledb/pipeline main* 14s
❯ rm test.mp3
  python3 scripts/phase1_acquire.py --batch config/test_batch.txt
Downloading 1/30: BwfqvpCAdeQ  ... done [28.7s]
Downloading 2/30: ILVeTE6416Q  ... done [34.2s]
Downloading 3/30: vLWFRNY10ww  ... done [30.3s]
Downloading 4/30: Dcfs_wKVi9A  ... done [30.4s]
Downloading 5/30: CFSLE4rFbPI  ... done [34.8s]
Downloading 6/30: 8f7oydDMu1c  ... done [39.3s]
Downloading 7/30: SDxziQtijtM  ... done [18.5s]
Downloading 8/30: 5FlI4pCEnbA  ... done [40.5s]
Downloading 9/30: ZWwwmcow64Q  ... done [70.1s]
Downloading 10/30: r8OqkxuHO5Y  ... done [37.6s]
Downloading 11/30: otZTFDdvnrU  ... done [20.1s]
Downloading 12/30: eut9zhDgvIk  ... done [33.5s]
Downloading 13/30: 9_IJBYW4vWM  ... done [26.9s]
Downloading 14/30: 2Y4A0FQVhEU  ... done [24.8s]
Downloading 15/30: V3QCLF3uju8  ... done [29.7s]
Downloading 16/30: 8n8C91eU1Os  ... done [90.7s]
Downloading 17/30: 9lgi73X4oGU  ... done [27.8s]
Downloading 18/30: Uh9XZtFYDK0  ... done [21.5s]
Downloading 19/30: fqi0tOGh7r0  ... done [44.0s]
Downloading 20/30: 3Tsj8yHFeZU  ... done [31.7s]
Downloading 21/30: 5sMtashu7IM  ... done [37.7s]
Downloading 22/30: -DD4PEUheLU  ... done [46.1s]
Downloading 23/30: HGdeCh12MpU  ... done [37.1s]
Downloading 24/30: 5bRC4Oq8En8  ... done [49.0s]
Downloading 25/30: ExK9OxyaPJg  ... done [44.7s]
Downloading 26/30: CgPqS91kAWo  ... done [33.8s]
Downloading 27/30: TiYNdk28WxA  ... done [43.1s]
Downloading 28/30: _GwN6SiRpzE  ... done [50.2s]
Downloading 29/30: ZKv4Uf8Bt0g  ... done [75.9s]
Downloading 30/30: bawGcAsAA-w  ... done [105.6s]

--- Download Summary ---
Total urls: 30
Success:    30
Skipped:    0
Failed:     0

~/dev/projects/tripledb/pipeline main* 20m 38s
❯ python3 scripts/phase2_transcribe.py --batch config/test_batch.txt
Loading faster-whisper large-v3 model on CUDA...
Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
Transcribing BwfqvpCAdeQ (1/30)... failed [1.9s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing ILVeTE6416Q (2/30)... failed [2.0s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing vLWFRNY10ww (3/30)... failed [2.4s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing Dcfs_wKVi9A (4/30)... failed [2.8s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing CFSLE4rFbPI (5/30)... failed [2.6s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing 8f7oydDMu1c (6/30)... failed [3.8s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing SDxziQtijtM (7/30)... failed [4.0s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing 5FlI4pCEnbA (8/30)... failed [4.3s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing ZWwwmcow64Q (9/30)... failed [4.4s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing r8OqkxuHO5Y (10/30)... failed [4.4s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing otZTFDdvnrU (11/30)... failed [5.2s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing eut9zhDgvIk (12/30)... failed [4.7s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing 9_IJBYW4vWM (13/30)... failed [4.7s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing 2Y4A0FQVhEU (14/30)... failed [4.8s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing V3QCLF3uju8 (15/30)... failed [5.3s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing 8n8C91eU1Os (16/30)... failed [5.5s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing 9lgi73X4oGU (17/30)... failed [5.9s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing Uh9XZtFYDK0 (18/30)... failed [5.5s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing fqi0tOGh7r0 (19/30)... failed [5.2s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing 3Tsj8yHFeZU (20/30)... failed [5.5s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing 5sMtashu7IM (21/30)... failed [5.8s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing -DD4PEUheLU (22/30)... failed [6.5s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing HGdeCh12MpU (23/30)... failed [6.8s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing 5bRC4Oq8En8 (24/30)... failed [12.2s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing ExK9OxyaPJg (25/30)... failed [14.0s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing CgPqS91kAWo (26/30)... failed [12.7s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing TiYNdk28WxA (27/30)... failed [16.7s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing _GwN6SiRpzE (28/30)... failed [26.9s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing ZKv4Uf8Bt0g (29/30)... failed [36.4s]
  Error: Library libcublas.so.12 is not found or cannot be loaded
Transcribing bawGcAsAA-w (30/30)... failed [111.8s]
  Error: Library libcublas.so.12 is not found or cannot be loaded

--- Transcription Summary ---
Total processed: 0
Total segments:  0
Low confidence:  0
Errors:          30

~/dev/projects/tripledb/pipeline main* 7m 58s
❯ ls -1 data/transcripts/*.json | wc -l
fish: No matches for wildcard 'data/transcripts/*.json'. See `help language#wildcards-globbing`.
ls -1 data/transcripts/*.json | wc -l
      ^~~~~~~~~~~~~~~~~~~~~~^

~/dev/projects/tripledb/pipeline main*
❯ 
~/dev/projects/tripledb/pipeline main*
❯ ollama list
  ollama search nemotron
NAME          ID              SIZE      MODIFIED    
qwen3.5:9b    6488c96fa5fa    6.6 GB    6 hours ago    
Error: unknown command "search" for "ollama"

~/dev/projects/tripledb/pipeline main*
❯ ollama pull nemotron
pulling manifest 
pulling c147388e9931: 100% ▕███████████████████▏  42 GB                         
pulling 4863fe3335f3: 100% ▕███████████████████▏ 1.2 KB                         
pulling 64e1b2889b78: 100% ▕███████████████████▏ 7.6 KB                         
pulling a568f2ebc73c: 100% ▕███████████████████▏ 4.7 KB                         
pulling 56bb8bd477a5: 100% ▕███████████████████▏   96 B                         
pulling 2b4e98e1c22e: 100% ▕███████████████████▏  562 B                         
verifying sha256 digest 
writing manifest 
success 

~/dev/projects/tripledb/pipeline main* 18m 24s
❯ 
