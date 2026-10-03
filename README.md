# Bomb-Game

SKIJUMP의 Rojo 설정 방식만 참고한 빈 프로젝트입니다. 게임 코드·모듈·패키지·에셋은 복사하지 않았습니다.

## Rojo 연결

Rojo 버전은 `7.7.0-rc.1`입니다. Rokit 또는 Aftman을 사용한다면 해당 도구의 `install` 명령으로 설치합니다.

프로젝트 루트에서 실행합니다.

```powershell
cd C:\Works\Bomb-Game
rojo serve default.project.json
```

Bomb-Game을 연 Studio의 Rojo 플러그인에서 `localhost:34873`에 연결합니다.
SKIJUMP의 `34872`와 다른 포트를 사용합니다. 같은 포트의 서버가 이미 실행 중이면 추가로 실행하지 않습니다.
대상 Place ID는 아직 설정하지 않았습니다. 게시 후 `default.project.json`의 `servePlaceIds`에 Bomb-Game의 Place ID를 지정합니다.

| 로컬 소스 | Studio |
| --- | --- |
| `src/ReplicatedStorage/BombGame` | `ReplicatedStorage.BombGame` |
| `src/ServerScriptService/BombGame` | `ServerScriptService.BombGame` |
| `src/StarterPlayerScripts/BombGame` | `StarterPlayer.StarterPlayerScripts.BombGame` |

소스 폴더에는 빈 폴더 유지를 위한 `.gitkeep`만 있습니다. 스크립트는 `src/`에서 작성하고 Rojo로 동기화합니다.
`$ignoreUnknownInstances`로 기존 Studio 오브젝트를 보존합니다. UI·맵·에셋은 Studio에서 편집합니다.
Workspace 속성은 변경하지 않습니다. `.rbxl`, `.rbxlx`, `.rblx` 파일은 임시 파일도 생성하지 않습니다.

## 검증

```powershell
rojo sourcemap default.project.json --output sourcemap.json
git diff --check
```
