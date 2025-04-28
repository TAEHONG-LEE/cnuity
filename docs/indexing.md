
이 오류는 `seats` 하위 컬렉션의 `reservedBy` 필드에 대한 **복합 인덱스가 생성되지 않았기 때문**입니다.

---

## 🛠️ 해결 방법: 인덱스 생성

### 👉 [여기를 클릭하여 인덱스를 자동 생성하세요](https://console.firebase.google.com/v1/r/project/cnuity-9653b/firestore/indexes?create_exemption=ClJwcm9qZWN0cy9jbnVpdHktOTY1M2IvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3NlYXRzL2ZpZWxkcy9yZXNlcnZlZEJ5EAIaDgoKcmVzZXJ2ZWRCeRAB)

해당 인덱스를 생성하면 1~3분 후 앱에서 정상 작동합니다.

---

## 📋 수동으로 인덱스 생성하는 방법

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 `cnuity-9653b` 선택
3. 왼쪽 메뉴 → Firestore Database → 상단 "Indexes" 탭 클릭
4. "Add Index" 클릭 후 아래와 같이 작성

| 항목         | 값             |
|--------------|----------------|
| Collection   | `seats`        |
| Field 1      | `reservedBy`   | Ascending |
| Field 2      | `__name__`     | Ascending |
| Scope        | Collection Group |

5. "Create" 클릭

---

## 💡 참고
이 인덱스는 다음 쿼리와 관련이 있습니다:

```dart
FirebaseFirestore.instance
  .collectionGroup('seats')
  .where('reservedBy', isEqualTo: currentUserUid)
