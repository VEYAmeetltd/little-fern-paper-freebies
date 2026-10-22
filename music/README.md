# Lovely Little Days songs

The mobile app reads `v1/songs.json` each time the music screen opens. The app keeps **Ice Cream on Halloween** inside the installation so there is still one song when the phone is offline. New songs live in `v1/tracks/` and appear after the public site updates. No Android or iOS app update is needed for another MP3.

To add a song from Windows PowerShell, use an MP3 that INTIES is allowed to publish:

```powershell
& 'C:\Etsy AutoShop\little-fern-free\music\add-song.ps1' -AudioPath 'C:\path\my-song.mp3' -Title 'My Song' -Description 'A little song to enjoy together.'
```

Check the title, description and audio. When ready, run the same command with `-Publish`. That copies the MP3, updates the song list, commits only those two song files and pushes this site's `main` branch. GitHub Pages may take a few minutes to update. Close and reopen the music screen to refresh its list.

Keep titles and descriptions family friendly. Only publish audio for which you own or have cleared the recording, composition and artwork rights. MP3s must be under 20 MB. The music list accepts up to 30 songs; more can be added later by extending the player and feed limits.
