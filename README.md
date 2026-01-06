# daily_lamp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# 1년 성경 통독 Flutter 앱 - 수정된 기획 및 설계안

## 📋 프로젝트 개요

**앱 이름 제안**: "함께 성경 읽기" 또는 "Daily Bible Reading"

**핵심 가치**: 매일 성경을 읽고, 성경 전체를 이해하며, 기록하고 격려받는 일상 경건 생활 도우미

---

## 🎯 주요 기능 요구사항 (수정)

### 1. 핵심 기능
- **월별 캘린더 뷰**: 실제 년월일 캘린더, 데이터는 월일(MM-DD)로 관리
- **윤년 처리**: 2월 29일은 찬양 URL로 특별 처리
- **성경책 개요**: 66권 성경책별 개요 영상 페이지
- **개인 메모**: 날짜별 성경 구절 및 묵상 기록
- **진행률 추적**: 연간 미완료 날짜 카운트 및 시각화
- **격려 시스템**: 진행 상황에 따른 아이콘/메시지 표시
- **데이터 관리**: CSV 다운로드를 통한 YouTube URL 업데이트

---

## 💾 데이터베이스 설계 (수정)

### ERD 및 테이블 구조

#### 1. `bible_readings` 테이블 (수정)
```sql
CREATE TABLE bible_readings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    month INTEGER NOT NULL,         -- 1-12
    day INTEGER NOT NULL,           -- 1-31
    youtube_url TEXT NOT NULL,
    title TEXT,                     -- 예: "창세기 1-3장" 또는 "찬양"
    chapter_info TEXT,              -- 상세 챕터 정보
    is_special INTEGER DEFAULT 0,   -- 0: 일반, 1: 윤년 특별(찬양)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(month, day)
);

CREATE INDEX idx_month_day ON bible_readings(month, day);
CREATE INDEX idx_special ON bible_readings(is_special);

-- 2월 29일은 찬양 URL로 등록
-- INSERT INTO bible_readings (month, day, youtube_url, title, is_special) 
-- VALUES (2, 29, 'https://youtu.be/praise_url', '윤년 특별 찬양', 1);
```

#### 2. `bible_books` 테이블 (신규)
```sql
CREATE TABLE bible_books (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    book_number INTEGER NOT NULL UNIQUE,  -- 1-66
    testament TEXT NOT NULL,              -- 'OLD' or 'NEW'
    korean_name TEXT NOT NULL,            -- 창세기, 출애굽기 등
    english_name TEXT,                    -- Genesis, Exodus 등
    youtube_url TEXT NOT NULL,            -- 개요 영상 URL
    author TEXT,                          -- 저자
    chapters_count INTEGER,               -- 총 장 수
    summary TEXT,                         -- 간단한 요약
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_testament ON bible_books(testament);
CREATE INDEX idx_book_number ON bible_books(book_number);
```

#### 3. `reading_history` 테이블 (신규)
```sql
-- 실제 사용자가 읽은 기록 (년도별 관리)
CREATE TABLE reading_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    day INTEGER NOT NULL,
    is_completed INTEGER DEFAULT 0,
    completed_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(year, month, day)
);

CREATE INDEX idx_year_month_day ON reading_history(year, month, day);
CREATE INDEX idx_completed ON reading_history(is_completed);
```

#### 4. `user_notes` 테이블 (수정)
```sql
CREATE TABLE user_notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    day INTEGER NOT NULL,
    verse_reference TEXT,           -- 예: "창세기 1:1-3"
    note_content TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_year_month_day_note ON user_notes(year, month, day);
```

#### 5. `book_notes` 테이블 (신규)
```sql
-- 성경책별 개요 메모
CREATE TABLE book_notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id INTEGER NOT NULL,
    note_content TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES bible_books(id) ON DELETE CASCADE,
    UNIQUE(book_id)
);

CREATE INDEX idx_book_id ON book_notes(book_id);
```

---

## 🎨 UI/UX 설계 (수정)

### 화면 구성

#### 1. **홈 화면** (Main Dashboard) - 변경없음
```
┌─────────────────────────────────┐
│  🗓️ 2025년 성경 통독           │
├─────────────────────────────────┤
│                                 │
│  📊 진행 현황                   │
│  ━━━━━━━━━━░░░░░░░░ 245/365   │
│                                 │
│  ✅ 완료: 245일                 │
│  ⏳ 남은 날: 120일              │
│  🔥 연속: 7일                   │
│                                 │
│  [격려 아이콘 영역]             │
│  🎉 참 잘했어요!                │
│  계속 이어가세요!               │
│                                 │
│  [오늘의 성경 읽기] 버튼        │
│  [성경 66권 개요] 버튼          │
│                                 │
└─────────────────────────────────┘
```

#### 2. **월별 캘린더 화면** (수정)
```
┌─────────────────────────────────┐
│  ← 2025년 2월 →                │
├─────────────────────────────────┤
│  일  월  화  수  목  금  토     │
│                          1✅ 2✅ │
│  3✅  4✅  5✅  6✅  7✅  8⭕ 9   │
│  ...                            │
│  23  24  25  26  27  28  29🎵  │
│                                 │
│  범례:                          │
│  ✅ 완료   ⭕ 오늘   ⬜ 미완료  │
│  🎵 찬양 (윤년만)              │
└─────────────────────────────────┘

※ 2025년은 평년이므로 2/29 없음
※ 2024년은 윤년이므로 2/29에 🎵 표시
```

#### 3. **날짜별 상세 화면** (변경없음)
```
┌─────────────────────────────────┐
│  2025년 1월 8일                 │
├─────────────────────────────────┤
│  📖 창세기 1-3장                │
│                                 │
│  [▶ YouTube 영상 재생]          │
│                                 │
│  ✍️ 나의 묵상 노트              │
│  ┌─────────────────────────┐   │
│  │ 성경 구절:              │   │
│  │ [창세기 1:1 입력란]     │   │
│  │                         │   │
│  │ 묵상 내용:              │   │
│  │ [자유 텍스트 입력]      │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  [✅ 완료 표시]  [💾 저장]     │
└─────────────────────────────────┘
```

#### 4. **성경 66권 개요 화면** (신규)
```
┌─────────────────────────────────┐
│  📚 성경 66권 개요              │
├─────────────────────────────────┤
│                                 │
│  🔵 구약성경 (39권)             │
│  ┌─────────────────────────┐   │
│  │ 📖 창세기        [50장] │→│
│  │ 📖 출애굽기      [40장] │→│
│  │ 📖 레위기        [27장] │→│
│  │ ...                     │   │
│  └─────────────────────────┘   │
│                                 │
│  🔴 신약성경 (27권)             │
│  ┌─────────────────────────┐   │
│  │ 📖 마태복음      [28장] │→│
│  │ 📖 마가복음      [16장] │→│
│  │ 📖 누가복음      [24장] │→│
│  │ ...                     │   │
│  └─────────────────────────┘   │
│                                 │
│  [검색 🔍]                      │
└─────────────────────────────────┘
```

#### 5. **성경책 상세 화면** (신규)
```
┌─────────────────────────────────┐
│  ← 창세기                       │
├─────────────────────────────────┤
│  📖 구약성경 1권 / 50장         │
│                                 │
│  ✍️ 저자: 모세                  │
│  📅 기록 연대: BC 1445-1405    │
│                                 │
│  [▶ 개요 영상 보기]             │
│                                 │
│  📝 요약                        │
│  창세기는 천지창조와 인류의     │
│  시작, 족장들의 이야기를 담고   │
│  있습니다...                    │
│                                 │
│  ✍️ 나의 메모                   │
│  ┌─────────────────────────┐   │
│  │ [자유 텍스트 입력]      │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  [💾 저장]                      │
└─────────────────────────────────┘
```

#### 6. **설정/관리 화면** (수정)
```
┌─────────────────────────────────┐
│  ⚙️ 설정                        │
├─────────────────────────────────┤
│  📥 데이터 업데이트             │
│     ├─ 매일 읽기 URL (CSV)     │
│     └─ 성경 개요 URL (CSV)     │
│                                 │
│  💾 데이터 백업/복원            │
│     └─ 나의 묵상 노트 백업      │
│                                 │
│  📊 통계 보기                   │
│     └─ 연간 완독률 차트         │
│                                 │
│  🗓️ 년도 선택                   │
│     └─ 현재: 2025년             │
│                                 │
│  ℹ️ 앱 정보                     │
└─────────────────────────────────┘
```

---

## 📦 CSV 데이터 형식 (수정)

### 1. 매일 읽기 YouTube URL CSV
```csv
month,day,youtube_url,title,chapter_info,is_special
1,1,https://youtu.be/xxxxx,신년 특별말씀,창세기 1-3장,0
1,2,https://youtu.be/yyyyy,2일차,창세기 4-7장,0
1,3,https://youtu.be/zzzzz,3일차,창세기 8-11장,0
...
2,28,https://youtu.be/aaaaa,59일차,출애굽기 30-32장,0
2,29,https://youtu.be/bbbbb,윤년 특별 찬양,찬양 모음,1
...
12,31,https://youtu.be/ccccc,365일차,요한계시록 19-22장,0
```

### 2. 성경 66권 개요 CSV (신규)
```csv
book_number,testament,korean_name,english_name,youtube_url,author,chapters_count,summary
1,OLD,창세기,Genesis,https://youtu.be/gen_overview,모세,50,천지창조와 족장들의 역사
2,OLD,출애굽기,Exodus,https://youtu.be/exo_overview,모세,40,이스라엘의 출애굽과 율법
3,OLD,레위기,Leviticus,https://youtu.be/lev_overview,모세,27,제사와 성결 규례
...
40,NEW,마태복음,Matthew,https://youtu.be/mat_overview,마태,28,예수님의 생애와 가르침
41,NEW,마가복음,Mark,https://youtu.be/mark_overview,마가,16,예수님의 사역
...
66,NEW,요한계시록,Revelation,https://youtu.be/rev_overview,요한,22,종말과 새 하늘 새 땅
```

---

## 🗓️ 윤년 처리 로직

### Dart 코드 예제
```dart
class DateHelper {
  // 윤년 확인
  static bool isLeapYear(int year) {
    if (year % 400 == 0) return true;
    if (year % 100 == 0) return false;
    if (year % 4 == 0) return true;
    return false;
  }
  
  // 해당 년도의 총 일수
  static int getTotalDaysInYear(int year) {
    return isLeapYear(year) ? 366 : 365;
  }
  
  // 특정 날짜에 대한 읽기 데이터 가져오기
  static Future<BibleReading?> getReadingForDate(
    int year, int month, int day
  ) async {
    // 평년인데 2월 29일 요청 시 null 반환
    if (!isLeapYear(year) && month == 2 && day == 29) {
      return null;
    }
    
    // DB에서 월-일로 조회
    final reading = await db.query(
      'bible_readings',
      where: 'month = ? AND day = ?',
      whereArgs: [month, day],
    );
    
    // 윤년이고 2월 29일이면 is_special=1인 찬양 데이터
    if (isLeapYear(year) && month == 2 && day == 29) {
      return reading.where((r) => r['is_special'] == 1).firstOrNull;
    }
    
    return reading.firstOrNull;
  }
  
  // 캘린더에 2월 29일 표시 여부
  static bool shouldShow229(int year) {
    return isLeapYear(year);
  }
}
```

---

## 🔄 상태 관리 구조 (수정)

```dart
// 주요 Provider들
class BibleReadingProvider extends ChangeNotifier {
  int currentYear;
  
  - List<BibleReading> readings  // 365/366개 (월-일 기준)
  - fetchReadingByMonthDay(int month, int day)
  - getReadingForDate(int year, int month, int day)  // 윤년 처리
}

class BibleBooksProvider extends ChangeNotifier {
  - List<BibleBook> oldTestamentBooks  // 39권
  - List<BibleBook> newTestamentBooks  // 27권
  - BibleBook getBookByNumber(int bookNumber)
  - List<BibleBook> searchBooks(String keyword)
}

class ReadingHistoryProvider extends ChangeNotifier {
  int currentYear;
  
  - List<ReadingHistory> history  // 해당 년도 기록
  - markAsCompleted(int year, int month, int day)
  - getUncompletedCount(int year)
  - getTotalDaysForYear(int year)  // 365 or 366
  - getStreakDays(int year)
}

class UserNoteProvider extends ChangeNotifier {
  - saveNote(int year, int month, int day, String verse, String content)
  - getNoteByDate(int year, int month, int day)
}

class BookNoteProvider extends ChangeNotifier {
  - saveBookNote(int bookId, String content)
  - getBookNote(int bookId)
}

class ProgressProvider extends ChangeNotifier {
  int currentYear;
  
  - int totalDays  // 365 or 366
  - int completedDays
  - int streakDays
  - double progressPercentage
  - EncouragementLevel currentLevel
  
  - calculateProgress(int year)
}

class CsvImportProvider extends ChangeNotifier {
  - importReadingsFromCsv(File csvFile)
  - importBooksFromCsv(File csvFile)
  - validateReadingsCsv(List<List<dynamic>> data)
  - validateBooksCsv(List<List<dynamic>> data)
  - updateDatabase(List data, String type)
}

class YearSelectorProvider extends ChangeNotifier {
  - int selectedYear
  - setYear(int year)
  - List<int> availableYears  // 2024, 2025, 2026 등
}
```

---

## 🏗️ 데이터 구조 클래스

```dart
class BibleReading {
  final int id;
  final int month;        // 1-12
  final int day;          // 1-31
  final String youtubeUrl;
  final String title;
  final String? chapterInfo;
  final bool isSpecial;   // true면 윤년 찬양
  
  // 윤년 체크와 결합하여 사용
  bool isAvailableForYear(int year) {
    if (month == 2 && day == 29) {
      return DateHelper.isLeapYear(year);
    }
    return true;
  }
}

class BibleBook {
  final int id;
  final int bookNumber;   // 1-66
  final String testament; // 'OLD' or 'NEW'
  final String koreanName;
  final String englishName;
  final String youtubeUrl;
  final String? author;
  final int chaptersCount;
  final String? summary;
}

class ReadingHistory {
  final int id;
  final int year;
  final int month;
  final int day;
  final bool isCompleted;
  final DateTime? completedAt;
}

class UserNote {
  final int id;
  final int year;
  final int month;
  final int day;
  final String? verseReference;
  final String noteContent;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class BookNote {
  final int id;
  final int bookId;
  final String noteContent;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## 📱 개발 단계별 로드맵 (수정)

### Phase 1: 기본 인프라 (1-2주)
- [ ] Flutter 프로젝트 초기화
- [ ] SQLite 데이터베이스 설정 (5개 테이블)
- [ ] 데이터 모델 구현 (BibleReading, BibleBook, ReadingHistory 등)
- [ ] Repository 패턴 구현
- [ ] 윤년 처리 유틸리티 클래스

### Phase 2: 핵심 기능 - 매일 읽기 (2주)
- [ ] 월별 캘린더 UI 구현 (윤년 표시 포함)
- [ ] 날짜별 상세 화면
- [ ] YouTube 영상 재생 기능
- [ ] 메모 작성/저장 기능
- [ ] 년도 선택 기능

### Phase 3: 성경 66권 개요 (1-2주)
- [ ] 성경 66권 리스트 화면 (구약/신약 분리)
- [ ] 성경책 상세 화면
- [ ] 개요 영상 재생
- [ ] 성경책별 메모 기능
- [ ] 검색 기능

### Phase 4: 진행률 및 격려 시스템 (1주)
- [ ] 진행률 계산 로직 (365/366일 대응)
- [ ] 홈 대시보드 UI
- [ ] 격려 아이콘/메시지 시스템
- [ ] 연속 읽기 추적

### Phase 5: 데이터 관리 (1주)
- [ ] CSV Import 기능 (2종류)
  - [ ] 매일 읽기 URL
  - [ ] 성경 66권 개요
- [ ] 데이터 백업/복원
- [ ] 설정 화면

### Phase 6: 개선 및 배포 (1-2주)
- [ ] UI/UX 폴리싱
- [ ] 성능 최적화
- [ ] 테스트 (Unit, Widget, Integration)
- [ ] 윤년 엣지 케이스 테스트
- [ ] 앱 스토어 배포 준비

---

## 📊 성경 66권 기본 데이터 구조

### 구약성경 (39권)
```
1. 모세오경 (5권): 창세기~신명기
2. 역사서 (12권): 여호수아~에스더
3. 시가서 (5권): 욥기~아가
4. 대선지서 (5권): 이사야~다니엘
5. 소선지서 (12권): 호세아~말라기
```

### 신약성경 (27권)
```
1. 복음서 (4권): 마태~요한
2. 역사서 (1권): 사도행전
3. 바울서신 (13권): 로마서~히브리서
4. 공동서신 (8권): 야고보서~유다서
5. 예언서 (1권): 요한계시록
```

---

## 🎯 추가 고려사항

### 1. 윤년 처리 특이사항
- **2024년**: 윤년 (366일) - 2월 29일 찬양 표시
- **2025년**: 평년 (365일) - 2월 28일 다음이 3월 1일
- **캘린더 렌더링**: 년도에 따라 2월 달력 동적 생성
- **진행률 계산**: `completedDays / totalDays(365 or 366)`

### 2. 성경책 개요 활용
- 매일 읽기 전에 해당 성경책 개요 먼저 보기 권장
- 처음 성경을 읽는 사용자를 위한 가이드
- 성경책별 메모로 전체 이해도 향상

### 3. 데이터 마이그레이션
- 기존 년도 데이터 보존
- 새로운 년도로 전환 시 reading_history만 새로 생성
- bible_readings, bible_books는 공통 데이터

### 4. 네비게이션 구조
```
홈 화면
├─ 오늘의 성경 읽기 → 캘린더 → 날짜별 상세
└─ 성경 66권 개요 → 책 리스트 → 책 상세
```

---

## 💡 선택적 향상 기능 (추후 개발)

1. **성경 읽기 계획**: 다양한 통독 플랜 제공
2. **알림 기능**: 매일 정해진 시간 읽기 알림
3. **통계 차트**: 월별/연간 진행률, 성경책별 완독 현황
4. **위젯**: 홈 화면 위젯으로 오늘의 성경 표시
5. **다크 모드**: 야간 독서 모드
6. **북마크**: 좋아하는 성경책 즐겨찾기
7. **공유 기능**: 묵상 노트 SNS 공유

---

