# cicd
CICD 테스트 레포지터리

- 현재 진행 워크플로우

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

## Event Grid 사용

- 의문점 :  github Actions만으로 구현하는 것보다 Event Grid를 사용하는 것이 더 효율적인가?

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

    rectangle "Event Grid"

    rectangle "Logic App or Function App"
}

dev --> "Frontend Repo" : 1. main branch push
dev --> "Backend Repo" : 1. main branch push

"Frontend Repo" ---> "Frontend-ACR" : 2. image upload
"Backend Repo" ---> "Backend-ACR" : 2. image upload

"ACR" <--> "Event Grid" : 3. Watching changes
"Event Grid" --> "Logic App or Function App" : 4. excuted for running scripts in VM
"Logic App or Function App" --> "Azure VM" : 5. run scripts
cicd_Repo --> "Azure VM" : 6. git pull

@enduml


```


- Event Grid만으로 CD를 진행할 수 없다. CD를 위해 시작점이 되는 것일 뿐. 이 때, Logic App이나 Function App이 중간 다리가 되어야한다. 여기서 의문점은 Logic App의 경우 트리거가 될 때마다 비용이 청구된다. Function App의 경우는 트리거가 하나 더 생성되었다고 비용이 청구되는 것은 아니지만, 현재 Function App에서 오류가 나면 slack으로 알림이 오도록 구현되어 있다. 그럼 CD관련 로그도 Function App의 애플리케이션 오류와 함께 출력이 되는 것이기 때문에, 알림을 받는 데 불편함이 있을 것이라고 생각한다. Function App과 Application Insights를 free plan으로 새로 생성한다고 하더라도 관리 복잡성이 늘어난다. 
- 만약, VM안에 컨테이너가 잘못되어 삭제한 경우, 현재 어떤 이미지를 이용하여 배포하였는지 모를 수 있다. 버전 관리를 하려면 vm내부 스크립트에서 docker compose 이미지 태그를 Event Grid로부터 받은 값으로 변경한 후 commit, push하는 과정이 있어야한다.
