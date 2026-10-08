# WIN leaderboard

WinLeaderboard.server publishes the global top 20 saved WIN scores through an OrderedDataStore. WinRankStore maintains the index only after successful profile saves and after persistent profiles load, so Studio fallback balances never enter the live rankings. Studio uses a separate ranking store. Old profiles enter the ranking index when their owners next join; offline profiles are not scanned.

Scores are published with UpdateAsync and a maximum comparison, preventing a delayed older save from lowering a score. Unchanged scores skip writes. An unavailable ranking store does not block the main profile save or kick the player; the next save retries it. The board refreshes once per minute and keeps its last global result when fetching fails. Studio without API access shows the current server ranking with an explicit label.

Workspace.System.WinLeaderboard.WinLeaderboardSurface is authored in Studio Edit mode, including Rank01 through Rank20 in its ScrollingFrame. The client clones that authored SurfaceGui into PlayerGui for input and updates existing row text/images/visibility without constructing UI at runtime. WinLeaderboardUI only renders data into those fixed rows. The server ensures CanQuery is enabled for input. The authored board faces Back toward the lobby; a LeaderboardFace string attribute can select another NormalId face, such as Back. Rankings use a ScrollingFrame, with profile images, usernames, WIN counts and gold/silver/bronze accents for the first three places. The UI inherits the existing menu font.

Runtime code is managed by Rojo. No Studio playtest or real DataStore write is performed during implementation verification.
