# cicd
CICD 테스트 레포지터리

```plantuml

@startuml

actor dev

rectangle "Github" {
    rectangle "Frontend Repo"
    rectangle "Backend Repo"
    rectangle cicd_Repo [
        cicd repo
        ---
         ㄴ.github/workflows/deploy.yml
         ㄴresources/docker-compose.yml
         ㄴmanifest/image-manifest.yml
    ]

    "Frontend Repo" --> cicd_Repo : 3. image tag change and action trigger 
    "Backend Repo" --> cicd_Repo : 3. image tag change and action trigger
}

cloud "Azure" {
    rectangle "ACR" {
        rectangle "Frontend-ACR"
        rectangle "Backend-ACR"
    }

    rectangle "Azure VM" {
        rectangle "docker-compose" {
            rectangle "frontend container"
            rectangle "backend container"
        }
    }
}

dev --> "Frontend Repo" : 1. main branch push
dev --> "Backend Repo" : 1. main branch push

"Frontend Repo" ---> "Frontend-ACR" : 2. image upload
"Backend Repo" ---> "Backend-ACR" : 2. image upload

"cicd_Repo" --> "Azure VM" : 4. git pull

"Frontend-ACR" --> "frontend container" : 5. image pull
"Backend-ACR" --> "backend container" : 5. image pull

@enduml

```
- [frontend repo](https://github.com/Suah-Cho/frontend) 및 [backend repo](https://github.com/Suah-Cho/backend)
    - 1, 2, 3번 작업이 github actions workflow action으로 실행
- [cicd repo](https://github.com/Suah-Cho/cicd)
    - 4, 5번 작업이 cicd github actions workflow action으로 실행

=> 1, 2, 3번 작업이 프론트엔드와 백엔드 레포지터리에서 각각 실행이 되면 3번 작업(cicd/resources/docker-compose.yml의 이미지 태그 변경)으로 인해 자동으로 cicd github actions이 트리거된다.