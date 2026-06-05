"""Semantic menu keys and 11-language translations for FKKitExamples."""

# fmt: off

def _e(en, zh_hans, zh_hant, ja, ko, es, fr, de, pt_br, ar, ru):
    return {
        "en": en, "zh-Hans": zh_hans, "zh-Hant": zh_hant, "ja": ja, "ko": ko,
        "es": es, "fr": fr, "de": de, "pt-BR": pt_br, "ar": ar, "ru": ru,
    }

EXAMPLES_MENU = {
    "examples.app.title": _e(
        "FKKit Examples", "FKKit 示例", "FKKit 範例", "FKKit サンプル", "FKKit 예제",
        "Ejemplos FKKit", "Exemples FKKit", "FKKit-Beispiele", "Exemplos FKKit", "أمثلة FKKit", "Примеры FKKit"),
    "examples.menu.kit.fkuikit.title": _e(
        "FKUIKit", "FKUIKit", "FKUIKit", "FKUIKit", "FKUIKit",
        "FKUIKit", "FKUIKit", "FKUIKit", "FKUIKit", "FKUIKit", "FKUIKit"),
    "examples.menu.kit.fkuikit.subtitle": _e(
        "Foundational UI components and presentation infrastructure",
        "基础 UI 组件与展示基础设施", "基礎 UI 元件與展示基礎設施", "基盤 UI コンポーネントとプレゼンテーション基盤", "기본 UI 컴포넌트 및 프레젠테이션 인프라",
        "Componentes UI fundamentales e infraestructura de presentación", "Composants UI fondamentaux et infrastructure de présentation",
        "Grundlegende UI-Komponenten und Präsentationsinfrastruktur", "Componentes UI fundamentais e infraestrutura de apresentação",
        "مكونات واجهة أساسية وبنية عرض", "Базовые UI-компоненты и инфраструктура представления"),
    "examples.menu.kit.fkcorekit.title": _e(
        "FKCoreKit", "FKCoreKit", "FKCoreKit", "FKCoreKit", "FKCoreKit",
        "FKCoreKit", "FKCoreKit", "FKCoreKit", "FKCoreKit", "FKCoreKit", "FKCoreKit"),
    "examples.menu.kit.fkcorekit.subtitle": _e(
        "Core non-UI capabilities (networking, logging, utilities, etc.)",
        "核心非 UI 能力（网络、日志、工具等）", "核心非 UI 能力（網路、日誌、工具等）", "コア非 UI 機能（ネットワーク、ログ、ユーティリティなど）", "핵심 비 UI 기능(네트워킹, 로깅, 유틸 등)",
        "Capacidades centrales no UI (red, registro, utilidades, etc.)", "Capacités core non UI (réseau, journalisation, utilitaires, etc.)",
        "Kernfunktionen ohne UI (Netzwerk, Logging, Utilities usw.)", "Recursos centrais sem UI (rede, logs, utilitários etc.)",
        "قدرات أساسية غير UI (شبكة، سجلات، أدوات، إلخ)", "Основные возможности без UI (сеть, логи, утилиты и т.д.)"),
}

def _item(key: str, title_en: str, sub_en: str, title_zh, sub_zh, title_zht, sub_zht, title_ja, sub_ja, title_ko, sub_ko,
          title_es, sub_es, title_fr, sub_fr, title_de, sub_de, title_pt, sub_pt, title_ar, sub_ar, title_ru, sub_ru):
    EXAMPLES_MENU[f"examples.menu.item.{key}.title"] = _e(title_en, title_zh, title_zht, title_ja, title_ko, title_es, title_fr, title_de, title_pt, title_ar, title_ru)
    EXAMPLES_MENU[f"examples.menu.item.{key}.subtitle"] = _e(sub_en, sub_zh, sub_zht, sub_ja, sub_ko, sub_es, sub_fr, sub_de, sub_pt, sub_ar, sub_ru)

_item("actionsheet", "ActionSheet", "Hub: basics, appearance, selection, custom rows, toggle, lifecycle, live updates, presentation, builder, SwiftUI",
      "ActionSheet", "中心：基础、外观、选择、自定义行、开关、生命周期、实时更新、展示、构建器、SwiftUI",
      "ActionSheet", "中心：基礎、外觀、選擇、自訂列、開關、生命週期、即時更新、展示、建構器、SwiftUI",
      "ActionSheet", "ハブ：基本、外観、選択、カスタム行、トグル、ライフサイクル、ライブ更新、表示、ビルダー、SwiftUI",
      "ActionSheet", "허브: 기본, 외관, 선택, 사용자 행, 토글, 수명주기, 실시간 업데이트, 표시, 빌더, SwiftUI",
      "ActionSheet", "Hub: básicos, apariencia, selección, filas personalizadas, toggle, ciclo de vida, actualizaciones en vivo, presentación, builder, SwiftUI",
      "ActionSheet", "Hub : bases, apparence, sélection, lignes personnalisées, bascule, cycle de vie, mises à jour live, présentation, builder, SwiftUI",
      "ActionSheet", "Hub: Grundlagen, Erscheinungsbild, Auswahl, benutzerdefinierte Zeilen, Toggle, Lebenszyklus, Live-Updates, Präsentation, Builder, SwiftUI",
      "ActionSheet", "Hub: básicos, aparência, seleção, linhas personalizadas, toggle, ciclo de vida, atualizações ao vivo, apresentação, builder, SwiftUI",
      "ActionSheet", "مركز: أساسيات، مظهر، اختيار، صفوف مخصصة، تبديل، دورة حياة، تحديثات مباشرة، عرض، منشئ، SwiftUI",
      "ActionSheet", "Хаб: основы, внешний вид, выбор, пользовательские строки, переключатели, жизненный цикл, live-обновления, показ, builder, SwiftUI")

_item("badge", "Badge", "Dot, numeric & text badges, anchors, animations, TabBarItem",
      "Badge", "圆点、数字与文本徽章、锚点、动画、TabBarItem",
      "Badge", "圓點、數字與文字徽章、錨點、動畫、TabBarItem",
      "Badge", "ドット、数値・テキストバッジ、アンカー、アニメーション、TabBarItem",
      "Badge", "점, 숫자 및 텍스트 배지, 앵커, 애니메이션, TabBarItem",
      "Badge", "Insignias de punto, numéricas y de texto, anclas, animaciones, TabBarItem",
      "Badge", "Badges point, numériques et texte, ancres, animations, TabBarItem",
      "Badge", "Punkt-, Zahlen- und Text-Badges, Anker, Animationen, TabBarItem",
      "Badge", "Badges de ponto, numéricos e texto, âncoras, animações, TabBarItem",
      "Badge", "شارات نقطية ورقمية ونصية، مراسي، رسوم متحركة، TabBarItem",
      "Badge", "Точечные, числовые и текстовые бейджи, якоря, анимации, TabBarItem")

_item("blurview", "BlurView", "High-performance blur view examples (UIKit / SwiftUI / IB)",
      "BlurView", "高性能模糊视图示例（UIKit / SwiftUI / IB）",
      "BlurView", "高效能模糊視圖範例（UIKit / SwiftUI / IB）",
      "BlurView", "高性能ブラービューのサンプル（UIKit / SwiftUI / IB）",
      "BlurView", "고성능 블러 뷰 예제(UIKit / SwiftUI / IB)",
      "BlurView", "Ejemplos de vista blur de alto rendimiento (UIKit / SwiftUI / IB)",
      "BlurView", "Exemples de vue floue haute performance (UIKit / SwiftUI / IB)",
      "BlurView", "Hochleistungs-BlurView-Beispiele (UIKit / SwiftUI / IB)",
      "BlurView", "Exemplos de blur view de alto desempenho (UIKit / SwiftUI / IB)",
      "BlurView", "أمثلة عرض ضبابي عالي الأداء (UIKit / SwiftUI / IB)",
      "BlurView", "Примеры высокопроизводительного BlurView (UIKit / SwiftUI / IB)")

_item("button", "Button", "Basics, layout, interaction, appearance, loading, global style & IB",
      "Button", "基础、布局、交互、外观、加载、全局样式与 IB",
      "Button", "基礎、版面、互動、外觀、載入、全域樣式與 IB",
      "Button", "基本、レイアウト、操作、外観、読み込み、グローバルスタイルと IB",
      "Button", "기본, 레이아웃, 상호작용, 외관, 로딩, 전역 스타일 및 IB",
      "Button", "Básicos, diseño, interacción, apariencia, carga, estilo global e IB",
      "Button", "Bases, mise en page, interaction, apparence, chargement, style global et IB",
      "Button", "Grundlagen, Layout, Interaktion, Erscheinungsbild, Laden, globaler Stil und IB",
      "Button", "Básicos, layout, interação, aparência, carregamento, estilo global e IB",
      "Button", "أساسيات، تخطيط، تفاعل، مظهر، تحميل، نمط عام و IB",
      "Button", "Основы, layout, взаимодействие, внешний вид, загрузка, глобальный стиль и IB")

_item("callout", "Callout", "Hub: FKTooltip, FKPopover, placements, menus, coach mark, FKCallout builder",
      "Callout", "中心：FKTooltip、FKPopover、位置、菜单、引导标记、FKCallout 构建器",
      "Callout", "中心：FKTooltip、FKPopover、位置、選單、引導標記、FKCallout 建構器",
      "Callout", "ハブ：FKTooltip、FKPopover、配置、メニュー、コーチマーク、FKCallout ビルダー",
      "Callout", "허브: FKTooltip, FKPopover, 배치, 메뉴, 코치 마크, FKCallout 빌더",
      "Callout", "Hub: FKTooltip, FKPopover, ubicaciones, menús, coach mark, builder FKCallout",
      "Callout", "Hub : FKTooltip, FKPopover, placements, menus, coach mark, builder FKCallout",
      "Callout", "Hub: FKTooltip, FKPopover, Platzierungen, Menüs, Coach Mark, FKCallout-Builder",
      "Callout", "Hub: FKTooltip, FKPopover, posicionamentos, menus, coach mark, builder FKCallout",
      "Callout", "مركز: FKTooltip و FKPopover والمواضع والقوائم وعلامة التدريب ومنشئ FKCallout",
      "Callout", "Хаб: FKTooltip, FKPopover, размещение, меню, coach mark, конструктор FKCallout")

_item("cornershadow", "CornerShadow", "Any-corner radius + high-performance shadow (path based)",
      "CornerShadow", "任意圆角 + 高性能阴影（基于路径）",
      "CornerShadow", "任意圓角 + 高效能陰影（基於路徑）",
      "CornerShadow", "任意コーナー半径 + 高性能シャドウ（パスベース）",
      "CornerShadow", "임의 모서리 반경 + 고성능 그림자(경로 기반)",
      "CornerShadow", "Radio en cualquier esquina + sombra de alto rendimiento (basada en path)",
      "CornerShadow", "Rayon sur n'importe quel coin + ombre haute performance (basée sur path)",
      "CornerShadow", "Radius an beliebiger Ecke + leistungsstarke Schatten (pfadbasiert)",
      "CornerShadow", "Raio em qualquer canto + sombra de alto desempenho (baseada em path)",
      "CornerShadow", "نصف قطر في أي زاوية + ظل عالي الأداء (قائم على المسار)",
      "CornerShadow", "Скругление любого угла + высокопроизводительная тень (на основе path)")

_item("divider", "Divider", "Hub: basics, line styles, edge pinning, defaults, SwiftUI",
      "Divider", "中心：基础、线型、边缘固定、默认值、SwiftUI",
      "Divider", "中心：基礎、線型、邊緣固定、預設值、SwiftUI",
      "Divider", "ハブ：基本、線スタイル、エッジ固定、デフォルト、SwiftUI",
      "Divider", "허브: 기본, 선 스타일, 가장자리 고정, 기본값, SwiftUI",
      "Divider", "Hub: básicos, estilos de línea, fijación de bordes, valores predeterminados, SwiftUI",
      "Divider", "Hub : bases, styles de ligne, ancrage des bords, valeurs par défaut, SwiftUI",
      "Divider", "Hub: Grundlagen, Linienstile, Kantenfixierung, Standardwerte, SwiftUI",
      "Divider", "Hub: básicos, estilos de linha, fixação de bordas, padrões, SwiftUI",
      "Divider", "مركز: أساسيات، أنماط خط، تثبيت الحافة، افتراضيات، SwiftUI",
      "Divider", "Хаб: основы, стили линий, закрепление краёв, значения по умолчанию, SwiftUI")

_item("emptystate", "EmptyState", "Hub: basics (empty/error/offline) and advanced (i18n, resolver, RTL)",
      "EmptyState", "中心：基础（空/错误/离线）与高级（i18n、解析器、RTL）",
      "EmptyState", "中心：基礎（空/錯誤/離線）與進階（i18n、解析器、RTL）",
      "EmptyState", "ハブ：基本（空/エラー/オフライン）と高度（i18n、リゾルバ、RTL）",
      "EmptyState", "허브: 기본(비어 있음/오류/오프라인) 및 고급(i18n, 리졸버, RTL)",
      "EmptyState", "Hub: básicos (vacío/error/offline) y avanzado (i18n, resolver, RTL)",
      "EmptyState", "Hub : bases (vide/erreur/hors ligne) et avancé (i18n, resolver, RTL)",
      "EmptyState", "Hub: Grundlagen (leer/Fehler/offline) und erweitert (i18n, Resolver, RTL)",
      "EmptyState", "Hub: básicos (vazio/erro/offline) e avançado (i18n, resolver, RTL)",
      "EmptyState", "مركز: أساسيات (فارغ/خطأ/غير متصل) ومتقدم (i18n، محلل، RTL)",
      "EmptyState", "Хаб: основы (пусто/ошибка/offline) и продвинутое (i18n, resolver, RTL)")

_item("expandabletext", "ExpandableText", "Hub: UILabel / UITextView / SwiftUI (shared support + Examples/)",
      "ExpandableText", "中心：UILabel / UITextView / SwiftUI（共享 Support + Examples/）",
      "ExpandableText", "中心：UILabel / UITextView / SwiftUI（共享 Support + Examples/）",
      "ExpandableText", "ハブ：UILabel / UITextView / SwiftUI（共有 Support + Examples/）",
      "ExpandableText", "허브: UILabel / UITextView / SwiftUI(공유 Support + Examples/)",
      "ExpandableText", "Hub: UILabel / UITextView / SwiftUI (Support compartido + Examples/)",
      "ExpandableText", "Hub : UILabel / UITextView / SwiftUI (Support partagé + Examples/)",
      "ExpandableText", "Hub: UILabel / UITextView / SwiftUI (gemeinsames Support + Examples/)",
      "ExpandableText", "Hub: UILabel / UITextView / SwiftUI (Support compartilhado + Examples/)",
      "ExpandableText", "مركز: UILabel / UITextView / SwiftUI (Support مشترك + Examples/)",
      "ExpandableText", "Хаб: UILabel / UITextView / SwiftUI (общий Support + Examples/)")

_item("videoplayer", "VideoPlayer", "Hub: VOD/HLS/live, playlist, subtitles, feed pool, offline, ads, QoE, SwiftUI",
      "VideoPlayer", "中心：点播/HLS/直播、播放列表、字幕、Feed 池、离线、广告、QoE、SwiftUI",
      "VideoPlayer", "中心：點播/HLS/直播、播放清單、字幕、Feed 池、離線、廣告、QoE、SwiftUI",
      "VideoPlayer", "ハブ：VOD/HLS/ライブ、プレイリスト、字幕、フィードプール、オフライン、広告、QoE、SwiftUI",
      "VideoPlayer", "허브: VOD/HLS/라이브, 재생 목록, 자막, 피드 풀, 오프라인, 광고, QoE, SwiftUI",
      "VideoPlayer", "Hub: VOD/HLS/en vivo, lista, subtítulos, pool de feed, offline, anuncios, QoE, SwiftUI",
      "VideoPlayer", "Hub : VOD/HLS/direct, playlist, sous-titres, pool de flux, offline, pubs, QoE, SwiftUI",
      "VideoPlayer", "Hub: VOD/HLS/Live, Playlist, Untertitel, Feed-Pool, Offline, Ads, QoE, SwiftUI",
      "VideoPlayer", "Hub: VOD/HLS/ao vivo, playlist, legendas, pool de feed, offline, anúncios, QoE, SwiftUI",
      "VideoPlayer", "مركز: VOD/HLS/مباشر، قائمة، ترجمات، مجموعة feed، offline، إعلانات، QoE، SwiftUI",
      "VideoPlayer", "Хаб: VOD/HLS/live, плейлист, субтитры, feed pool, offline, реклама, QoE, SwiftUI")

_item("audioplayer", "AudioPlayer", "Hub: MP3/HLS, queue modes, lyrics, mini bar, sleep timer, history, QoE, SwiftUI",
      "AudioPlayer", "中心：MP3/HLS、队列模式、歌词、迷你栏、睡眠定时、历史、QoE、SwiftUI",
      "AudioPlayer", "中心：MP3/HLS、佇列模式、歌詞、迷你列、睡眠定時、歷史、QoE、SwiftUI",
      "AudioPlayer", "ハブ：MP3/HLS、キューモード、歌詞、ミニバー、スリープタイマー、履歴、QoE、SwiftUI",
      "AudioPlayer", "허브: MP3/HLS, 큐 모드, 가사, 미니 바, 수면 타이머, 기록, QoE, SwiftUI",
      "AudioPlayer", "Hub: MP3/HLS, modos de cola, letras, mini barra, temporizador de sueño, historial, QoE, SwiftUI",
      "AudioPlayer", "Hub : MP3/HLS, modes file, paroles, mini barre, minuterie sommeil, historique, QoE, SwiftUI",
      "AudioPlayer", "Hub: MP3/HLS, Warteschlangenmodi, Lyrics, Mini-Leiste, Schlaf-Timer, Verlauf, QoE, SwiftUI",
      "AudioPlayer", "Hub: MP3/HLS, modos de fila, letras, mini barra, timer de sono, histórico, QoE, SwiftUI",
      "AudioPlayer", "مركز: MP3/HLS، أوضاع قائمة، كلمات، شريط مصغر، مؤقت نوم، سجل، QoE، SwiftUI",
      "AudioPlayer", "Хаб: MP3/HLS, режимы очереди, тексты, мини-панель, таймер сна, история, QoE, SwiftUI")

_item("pagingcontroller", "PagingController", "FKTabBar ↔ UIPageViewController sync: lazy/SwiftUI/delegate, RTL & gestures (Public/Internal/Extension)",
      "PagingController", "FKTabBar ↔ UIPageViewController 同步：lazy/SwiftUI/delegate、RTL 与手势（Public/Internal/Extension）",
      "PagingController", "FKTabBar ↔ UIPageViewController 同步：lazy/SwiftUI/delegate、RTL 與手勢（Public/Internal/Extension）",
      "PagingController", "FKTabBar ↔ UIPageViewController 同期：lazy/SwiftUI/delegate、RTL とジェスチャ（Public/Internal/Extension）",
      "PagingController", "FKTabBar ↔ UIPageViewController 동기화: lazy/SwiftUI/delegate, RTL 및 제스처(Public/Internal/Extension)",
      "PagingController", "Sincronización FKTabBar ↔ UIPageViewController: lazy/SwiftUI/delegate, RTL y gestos (Public/Internal/Extension)",
      "PagingController", "Sync FKTabBar ↔ UIPageViewController : lazy/SwiftUI/delegate, RTL et gestes (Public/Internal/Extension)",
      "PagingController", "FKTabBar ↔ UIPageViewController-Sync: lazy/SwiftUI/delegate, RTL und Gesten (Public/Internal/Extension)",
      "PagingController", "Sincronização FKTabBar ↔ UIPageViewController: lazy/SwiftUI/delegate, RTL e gestos (Public/Internal/Extension)",
      "PagingController", "مزامنة FKTabBar ↔ UIPageViewController: lazy/SwiftUI/delegate وRTL وإيماءات (Public/Internal/Extension)",
      "PagingController", "Синхронизация FKTabBar ↔ UIPageViewController: lazy/SwiftUI/delegate, RTL и жесты (Public/Internal/Extension)")

_item("sheetpresentationcontroller", "SheetPresentationController", "Custom SheetPresentationController examples (sheet/center/anchor, animation, backdrop, keyboard, rotation)",
      "SheetPresentationController", "自定义 SheetPresentationController 示例（sheet/center/anchor、动画、背景、键盘、旋转）",
      "SheetPresentationController", "自訂 SheetPresentationController 範例（sheet/center/anchor、動畫、背景、鍵盤、旋轉）",
      "SheetPresentationController", "カスタム SheetPresentationController サンプル（sheet/center/anchor、アニメ、背景、キーボード、回転）",
      "SheetPresentationController", "사용자 SheetPresentationController 예제(sheet/center/anchor, 애니메이션, 배경, 키보드, 회전)",
      "SheetPresentationController", "Ejemplos personalizados de SheetPresentationController (sheet/center/anchor, animación, fondo, teclado, rotación)",
      "SheetPresentationController", "Exemples SheetPresentationController personnalisés (sheet/center/anchor, animation, fond, clavier, rotation)",
      "SheetPresentationController", "Benutzerdefinierte SheetPresentationController-Beispiele (Sheet/Center/Anchor, Animation, Backdrop, Tastatur, Rotation)",
      "SheetPresentationController", "Exemplos personalizados de SheetPresentationController (sheet/center/anchor, animação, fundo, teclado, rotação)",
      "SheetPresentationController", "أمثلة SheetPresentationController مخصصة (sheet/center/anchor، رسوم، خلفية، لوحة مفاتيح، دوران)",
      "SheetPresentationController", "Примеры SheetPresentationController (sheet/center/anchor, анимация, фон, клавиатура, поворот)")

_item("progressbar", "ProgressBar", "Hub: interactive playground, preset gallery, delegate log, SwiftUI bridge, RTL & accessibility",
      "ProgressBar", "中心：交互 playground、预设库、delegate 日志、SwiftUI 桥接、RTL 与无障碍",
      "ProgressBar", "中心：互動 playground、預設庫、delegate 日誌、SwiftUI 橋接、RTL 與無障礙",
      "ProgressBar", "ハブ：インタラクティブ playground、プリセットギャラリー、delegate ログ、SwiftUI ブリッジ、RTL とアクセシビリティ",
      "ProgressBar", "허브: 대화형 playground, 프리셋 갤러리, delegate 로그, SwiftUI 브리지, RTL 및 접근성",
      "ProgressBar", "Hub: playground interactivo, galería de presets, log delegate, puente SwiftUI, RTL y accesibilidad",
      "ProgressBar", "Hub : playground interactif, galerie de presets, journal delegate, pont SwiftUI, RTL et accessibilité",
      "ProgressBar", "Hub: interaktives Playground, Preset-Galerie, Delegate-Log, SwiftUI-Bridge, RTL und Barrierefreiheit",
      "ProgressBar", "Hub: playground interativo, galeria de presets, log delegate, ponte SwiftUI, RTL e acessibilidade",
      "ProgressBar", "مركز: playground تفاعلي، معرض presets، سجل delegate، جسر SwiftUI، RTL وإمكانية الوصول",
      "ProgressBar", "Хаб: интерактивный playground, галерея пресетов, delegate log, мост SwiftUI, RTL и доступность")

_item("ratingcontrol", "RatingControl", "Hub: interactive/read-only stars, icon presets, playground, delegate, SwiftUI, RTL & a11y",
      "RatingControl", "中心：交互/只读星级、图标预设、playground、delegate、SwiftUI、RTL 与无障碍",
      "RatingControl", "中心：互動/唯讀星級、圖示預設、playground、delegate、SwiftUI、RTL 與無障礙",
      "RatingControl", "ハブ：インタラクティブ/読み取り専用スター、アイコンプリセット、playground、delegate、SwiftUI、RTL と a11y",
      "RatingControl", "허브: 대화형/읽기 전용 별, 아이콘 프리셋, playground, delegate, SwiftUI, RTL 및 a11y",
      "RatingControl", "Hub: estrellas interactivas/solo lectura, presets de iconos, playground, delegate, SwiftUI, RTL y a11y",
      "RatingControl", "Hub : étoiles interactives/lecture seule, presets d'icônes, playground, delegate, SwiftUI, RTL et a11y",
      "RatingControl", "Hub: interaktive/nur-Lese-Sterne, Icon-Presets, Playground, Delegate, SwiftUI, RTL und a11y",
      "RatingControl", "Hub: estrelas interativas/somente leitura, presets de ícones, playground, delegate, SwiftUI, RTL e a11y",
      "RatingControl", "مركز: نجوم تفاعلية/للقراءة فقط، presets أيقونات، playground، delegate، SwiftUI، RTL وa11y",
      "RatingControl", "Хаб: интерактивные/только чтение звёзды, пресеты иконок, playground, delegate, SwiftUI, RTL и a11y")

_item("refresh", "Refresh", "Hub: default, GIF, hosted, delegate, settings, collection, scroll view, …",
      "Refresh", "中心：默认、GIF、托管、delegate、设置、集合、滚动视图等",
      "Refresh", "中心：預設、GIF、託管、delegate、設定、集合、捲動視圖等",
      "Refresh", "ハブ：デフォルト、GIF、ホスト、delegate、設定、コレクション、スクロールビューなど",
      "Refresh", "허브: 기본, GIF, 호스팅, delegate, 설정, 컬렉션, 스크롤 뷰 등",
      "Refresh", "Hub: predeterminado, GIF, alojado, delegate, ajustes, colección, scroll view, …",
      "Refresh", "Hub : par défaut, GIF, hébergé, delegate, réglages, collection, scroll view, …",
      "Refresh", "Hub: Standard, GIF, gehostet, Delegate, Einstellungen, Collection, Scroll View, …",
      "Refresh", "Hub: padrão, GIF, hospedado, delegate, configurações, coleção, scroll view, …",
      "Refresh", "مركز: افتراضي، GIF، مستضاف، delegate، إعدادات، مجموعة، scroll view، …",
      "Refresh", "Хаб: по умолчанию, GIF, hosted, delegate, настройки, collection, scroll view, …")

_item("skeleton", "Skeleton", "Hub: overlay, auto, presets, container, lists, manager, global defaults",
      "Skeleton", "中心：overlay、auto、预设、容器、列表、管理器、全局默认",
      "Skeleton", "中心：overlay、auto、預設、容器、列表、管理器、全域預設",
      "Skeleton", "ハブ：overlay、auto、プリセット、コンテナ、リスト、マネージャー、グローバルデフォルト",
      "Skeleton", "허브: overlay, auto, 프리셋, 컨테이너, 목록, 매니저, 전역 기본값",
      "Skeleton", "Hub: overlay, auto, presets, contenedor, listas, manager, valores globales",
      "Skeleton", "Hub : overlay, auto, presets, conteneur, listes, manager, valeurs globales",
      "Skeleton", "Hub: Overlay, Auto, Presets, Container, Listen, Manager, globale Standardwerte",
      "Skeleton", "Hub: overlay, auto, presets, container, listas, manager, padrões globais",
      "Skeleton", "مركز: overlay، auto، presets، حاوية، قوائم، مدير، افتراضيات عامة",
      "Skeleton", "Хаб: overlay, auto, presets, container, lists, manager, глобальные значения по умолчанию")

_item("tabbar", "TabBar", "Segmented tab bar with indicators, dynamic data, width policies, and a11y/i18n examples",
      "TabBar", "分段 TabBar：指示器、动态数据、宽度策略及无障碍/i18n 示例",
      "TabBar", "分段 TabBar：指示器、動態資料、寬度策略及無障礙/i18n 範例",
      "TabBar", "セグメント TabBar：インジケーター、動的データ、幅ポリシー、a11y/i18n サンプル",
      "TabBar", "세그먼트 TabBar: 인디케이터, 동적 데이터, 너비 정책, a11y/i18n 예제",
      "TabBar", "TabBar segmentada con indicadores, datos dinámicos, políticas de ancho y ejemplos a11y/i18n",
      "TabBar", "TabBar segmentée avec indicateurs, données dynamiques, politiques de largeur et exemples a11y/i18n",
      "TabBar", "Segmentierte TabBar mit Indikatoren, dynamischen Daten, Breitenrichtlinien und a11y/i18n-Beispielen",
      "TabBar", "TabBar segmentada com indicadores, dados dinâmicos, políticas de largura e exemplos a11y/i18n",
      "TabBar", "TabBar مقسمة مع مؤشرات وبيانات ديناميكية وسياسات عرض وأمثلة a11y/i18n",
      "TabBar", "Сегментированная TabBar с индикаторами, динамическими данными, политиками ширины и примерами a11y/i18n")

_item("textfield", "TextField", "Formatted input, validation, style customization, callbacks, and global defaults",
      "TextField", "格式化输入、校验、样式定制、回调与全局默认",
      "TextField", "格式化輸入、驗證、樣式自訂、回呼與全域預設",
      "TextField", "書式入力、検証、スタイルカスタム、コールバック、グローバルデフォルト",
      "TextField", "형식 입력, 검증, 스타일 사용자 지정, 콜백, 전역 기본값",
      "TextField", "Entrada formateada, validación, personalización de estilo, callbacks y valores globales",
      "TextField", "Saisie formatée, validation, personnalisation du style, callbacks et valeurs globales",
      "TextField", "Formatierte Eingabe, Validierung, Stilanpassung, Callbacks und globale Standardwerte",
      "TextField", "Entrada formatada, validação, personalização de estilo, callbacks e padrões globais",
      "TextField", "إدخال منسق، تحقق، تخصيص النمط، callbacks وافتراضيات عامة",
      "TextField", "Форматированный ввод, валидация, настройка стиля, callbacks и глобальные значения")

_item("toast", "Toast", "Global Toast/HUD/Snackbar hints with queueing, styles, positions, custom view, and SwiftUI support",
      "Toast", "全局 Toast/HUD/Snackbar：队列、样式、位置、自定义视图与 SwiftUI 支持",
      "Toast", "全域 Toast/HUD/Snackbar：佇列、樣式、位置、自訂視圖與 SwiftUI 支援",
      "Toast", "グローバル Toast/HUD/Snackbar：キュー、スタイル、位置、カスタムビュー、SwiftUI 対応",
      "Toast", "전역 Toast/HUD/Snackbar: 큐, 스타일, 위치, 사용자 뷰, SwiftUI 지원",
      "Toast", "Toast/HUD/Snackbar global con cola, estilos, posiciones, vista personalizada y SwiftUI",
      "Toast", "Toast/HUD/Snackbar global avec file, styles, positions, vue personnalisée et SwiftUI",
      "Toast", "Globales Toast/HUD/Snackbar mit Warteschlange, Stilen, Positionen, Custom View und SwiftUI",
      "Toast", "Toast/HUD/Snackbar global com fila, estilos, posições, view personalizada e SwiftUI",
      "Toast", "Toast/HUD/Snackbar عام مع قائمة انتظار وأنماط ومواضع وعرض مخصص وSwiftUI",
      "Toast", "Глобальный Toast/HUD/Snackbar: очередь, стили, позиции, custom view и SwiftUI")

_item("async", "Async", "Main/background dispatch, delay cancel, debounce, throttle, groups, executors",
      "Async", "主线程/后台调度、延迟取消、防抖、节流、分组、执行器",
      "Async", "主執行緒/背景調度、延遲取消、防抖、節流、分組、執行器",
      "Async", "メイン/バックグラウンドディスパッチ、遅延キャンセル、デバウンス、スロットル、グループ、エグゼキュータ",
      "Async", "메인/백그라운드 디스패치, 지연 취소, 디바운스, 스로틀, 그룹, 실행기",
      "Async", "Despacho main/background, cancelación de delay, debounce, throttle, grupos, ejecutores",
      "Async", "Dispatch main/arrière-plan, annulation de délai, debounce, throttle, groupes, exécuteurs",
      "Async", "Main/Background-Dispatch, Delay-Abbruch, Debounce, Throttle, Gruppen, Executors",
      "Async", "Dispatch main/background, cancelamento de delay, debounce, throttle, grupos, executores",
      "Async", "إرسال main/background، إلغاء التأخير، debounce، throttle، مجموعات، منفذون",
      "Async", "Main/background dispatch, отмена delay, debounce, throttle, группы, executors")

_item("businesskit", "BusinessKit", "Version, tracking, i18n, lifecycle, deeplink, device info, business utils",
      "BusinessKit", "版本、追踪、i18n、生命周期、deeplink、设备信息、业务工具",
      "BusinessKit", "版本、追蹤、i18n、生命週期、deeplink、裝置資訊、業務工具",
      "BusinessKit", "バージョン、トラッキング、i18n、ライフサイクル、deeplink、デバイス情報、ビジネスユーティリティ",
      "BusinessKit", "버전, 추적, i18n, 수명주기, deeplink, 기기 정보, 비즈니스 유틸",
      "BusinessKit", "Versión, tracking, i18n, ciclo de vida, deeplink, info del dispositivo, utilidades de negocio",
      "BusinessKit", "Version, tracking, i18n, cycle de vie, deeplink, infos appareil, utilitaires métier",
      "BusinessKit", "Version, Tracking, i18n, Lebenszyklus, Deeplink, Geräteinfo, Business-Utils",
      "BusinessKit", "Versão, tracking, i18n, ciclo de vida, deeplink, info do dispositivo, utilitários de negócio",
      "BusinessKit", "إصدار، تتبع، i18n، دورة حياة، deeplink، معلومات الجهاز، أدوات الأعمال",
      "BusinessKit", "Версия, tracking, i18n, жизненный цикл, deeplink, информация об устройстве, business utils")

_item("filemanager", "FileManager", "Sandbox/file ops, read/write, resumable download, upload, cache and ZIP APIs",
      "FileManager", "沙盒/文件操作、读写、断点下载、上传、缓存与 ZIP API",
      "FileManager", "沙盒/檔案操作、讀寫、斷點下載、上傳、快取與 ZIP API",
      "FileManager", "サンドボックス/ファイル操作、読み書き、再開ダウンロード、アップロード、キャッシュと ZIP API",
      "FileManager", "샌드박스/파일 작업, 읽기/쓰기, 이어받기 다운로드, 업로드, 캐시 및 ZIP API",
      "FileManager", "Sandbox/operaciones de archivo, lectura/escritura, descarga reanudable, subida, caché y APIs ZIP",
      "FileManager", "Sandbox/opérations fichier, lecture/écriture, téléchargement reprise, upload, cache et APIs ZIP",
      "FileManager", "Sandbox/Dateioperationen, Lesen/Schreiben, fortsetzbare Downloads, Upload, Cache und ZIP-APIs",
      "FileManager", "Sandbox/operações de arquivo, leitura/gravação, download retomável, upload, cache e APIs ZIP",
      "FileManager", "Sandbox/عمليات ملفات، قراءة/كتابة، تنزيل قابل للاستئناف، رفع، ذاكرة مؤقتة وواجهات ZIP",
      "FileManager", "Sandbox/файловые операции, чтение/запись, докачка, upload, cache и ZIP API")

_item("i18n", "I18n", "In-app language switching, bundle lookup, formatters, dictionary, RTL, observers",
      "I18n", "应用内语言切换、Bundle 查找、格式化、字典、RTL、观察者",
      "I18n", "應用內語言切換、Bundle 查找、格式化、字典、RTL、觀察者",
      "I18n", "アプリ内言語切替、bundle ルックアップ、フォーマッタ、辞書、RTL、オブザーバー",
      "I18n", "앱 내 언어 전환, bundle 조회, 포맷터, 사전, RTL, 옵저버",
      "I18n", "Cambio de idioma en la app, búsqueda en bundle, formateadores, diccionario, RTL, observadores",
      "I18n", "Changement de langue in-app, recherche bundle, formateurs, dictionnaire, RTL, observateurs",
      "I18n", "In-App-Sprachwechsel, Bundle-Lookup, Formatter, Wörterbuch, RTL, Beobachter",
      "I18n", "Troca de idioma no app, lookup de bundle, formatadores, dicionário, RTL, observadores",
      "I18n", "تبديل اللغة داخل التطبيق، بحث bundle، formatters، قاموس، RTL، مراقبون",
      "I18n", "Смена языка в приложении, bundle lookup, форматтеры, словарь, RTL, наблюдатели")

_item("logger", "Logger", "5-level logs, config, file persistence, crash capture, export/clear",
      "Logger", "5 级日志、配置、文件持久化、崩溃捕获、导出/清除",
      "Logger", "5 級日誌、設定、檔案持久化、崩潰捕獲、匯出/清除",
      "Logger", "5 段階ログ、設定、ファイル永続化、クラッシュ捕捉、エクスポート/クリア",
      "Logger", "5단계 로그, 구성, 파일 영속화, 크래시 캡처, 내보내기/지우기",
      "Logger", "Logs de 5 niveles, config, persistencia en archivo, captura de crashes, exportar/limpiar",
      "Logger", "Journaux 5 niveaux, config, persistance fichier, capture de crash, export/effacer",
      "Logger", "5-Level-Logs, Config, Datei-Persistenz, Crash-Erfassung, Export/Löschen",
      "Logger", "Logs de 5 níveis, config, persistência em arquivo, captura de crash, exportar/limpar",
      "Logger", "سجلات 5 مستويات، إعداد، حفظ ملف، التقاط الأعطال، تصدير/مسح",
      "Logger", "5-уровневые логи, config, файловая persistence, crash capture, export/clear")

_item("network", "Network", "GET/POST, async/await, upload/download, cache, cancel, parsing",
      "Network", "GET/POST、async/await、上传/下载、缓存、取消、解析",
      "Network", "GET/POST、async/await、上傳/下載、快取、取消、解析",
      "Network", "GET/POST、async/await、アップロード/ダウンロード、キャッシュ、キャンセル、解析",
      "Network", "GET/POST, async/await, 업로드/다운로드, 캐시, 취소, 파싱",
      "Network", "GET/POST, async/await, subida/descarga, caché, cancelar, parsing",
      "Network", "GET/POST, async/await, upload/download, cache, annulation, parsing",
      "Network", "GET/POST, async/await, Upload/Download, Cache, Abbruch, Parsing",
      "Network", "GET/POST, async/await, upload/download, cache, cancelar, parsing",
      "Network", "GET/POST وasync/await ورفع/تنزيل وذاكرة مؤقتة وإلغاء وتحليل",
      "Network", "GET/POST, async/await, upload/download, cache, cancel, parsing")

_item("permissions", "Permissions", "Unified permission status/query/request, batch, denied handling, settings jump",
      "Permissions", "统一权限状态/查询/请求、批量、拒绝处理、跳转设置",
      "Permissions", "統一權限狀態/查詢/請求、批次、拒絕處理、跳轉設定",
      "Permissions", "統一権限ステータス/クエリ/リクエスト、バッチ、拒否処理、設定へジャンプ",
      "Permissions", "통합 권한 상태/조회/요청, 일괄, 거부 처리, 설정 이동",
      "Permissions", "Estado/consulta/solicitud unificados, lote, manejo de denegación, ir a ajustes",
      "Permissions", "Statut/requête unifiés, lot, gestion refus, ouverture réglages",
      "Permissions", "Einheitlicher Status/Abfrage/Anfrage, Batch, Ablehnungsbehandlung, Einstellungen",
      "Permissions", "Status/consulta/solicitação unificados, lote, tratamento de negação, ir às configurações",
      "Permissions", "حالة/استعلام/طلب موحد، دفعة، معالجة الرفض، الانتقال للإعدادات",
      "Permissions", "Единый status/query/request, batch, обработка отказа, переход в настройки")

_item("pluggable", "Pluggable", "Protocol contracts: networking, analytics, storage, session, routing, UIKit cells",
      "Pluggable", "协议契约：网络、分析、存储、会话、路由、UIKit 单元格",
      "Pluggable", "協定契約：網路、分析、儲存、工作階段、路由、UIKit 儲存格",
      "Pluggable", "プロトコル契約：ネットワーク、分析、ストレージ、セッション、ルーティング、UIKit セル",
      "Pluggable", "프로토콜 계약: 네트워킹, 분석, 저장소, 세션, 라우팅, UIKit 셀",
      "Pluggable", "Contratos de protocolo: red, analítica, almacenamiento, sesión, routing, celdas UIKit",
      "Pluggable", "Contrats de protocole : réseau, analytics, stockage, session, routing, cellules UIKit",
      "Pluggable", "Protokollverträge: Netzwerk, Analytics, Storage, Session, Routing, UIKit-Zellen",
      "Pluggable", "Contratos de protocolo: rede, analytics, armazenamento, sessão, roteamento, células UIKit",
      "Pluggable", "عقود بروتوكول: شبكة، تحليلات، تخزين، جلسة، توجيه، خلايا UIKit",
      "Pluggable", "Протокольные контракты: networking, analytics, storage, session, routing, UIKit cells")

_item("security", "Security", "Hash, AES, RSA, Base64/HEX/URL, HMAC, random, masking, wipe, anti-debug",
      "Security", "Hash、AES、RSA、Base64/HEX/URL、HMAC、随机、掩码、擦除、反调试",
      "Security", "Hash、AES、RSA、Base64/HEX/URL、HMAC、隨機、遮罩、擦除、反偵錯",
      "Security", "Hash、AES、RSA、Base64/HEX/URL、HMAC、ランダム、マスキング、ワイプ、反デバッグ",
      "Security", "Hash, AES, RSA, Base64/HEX/URL, HMAC, 난수, 마스킹, 와이프, 안티 디버그",
      "Security", "Hash, AES, RSA, Base64/HEX/URL, HMAC, aleatorio, enmascaramiento, borrado, anti-debug",
      "Security", "Hash, AES, RSA, Base64/HEX/URL, HMAC, aléatoire, masquage, effacement, anti-debug",
      "Security", "Hash, AES, RSA, Base64/HEX/URL, HMAC, Zufall, Maskierung, Wipe, Anti-Debug",
      "Security", "Hash, AES, RSA, Base64/HEX/URL, HMAC, aleatório, mascaramento, wipe, anti-debug",
      "Security", "Hash وAES وRSA وBase64/HEX/URL وHMAC وعشوائي وإخفاء ومسح ومضاد تصحيح",
      "Security", "Hash, AES, RSA, Base64/HEX/URL, HMAC, random, masking, wipe, anti-debug")

_item("storage", "Storage", "UserDefaults, Keychain, file, memory cache, TTL, purge, async",
      "Storage", "UserDefaults、Keychain、文件、内存缓存、TTL、清除、async",
      "Storage", "UserDefaults、Keychain、檔案、記憶體快取、TTL、清除、async",
      "Storage", "UserDefaults、Keychain、ファイル、メモリキャッシュ、TTL、パージ、async",
      "Storage", "UserDefaults, Keychain, 파일, 메모리 캐시, TTL, purge, async",
      "Storage", "UserDefaults, Keychain, archivo, caché en memoria, TTL, purge, async",
      "Storage", "UserDefaults, Keychain, fichier, cache mémoire, TTL, purge, async",
      "Storage", "UserDefaults, Keychain, Datei, Speichercache, TTL, Purge, async",
      "Storage", "UserDefaults, Keychain, arquivo, cache em memória, TTL, purge, async",
      "Storage", "UserDefaults وKeychain وملف وذاكرة مؤقتة وTTL وpurge وasync",
      "Storage", "UserDefaults, Keychain, file, memory cache, TTL, purge, async")

_item("utils", "Utils", "Date, regex, number, string, device, UI, collection, image and common helpers",
      "Utils", "日期、正则、数字、字符串、设备、UI、集合、图片及常用辅助",
      "Utils", "日期、正則、數字、字串、裝置、UI、集合、圖片及常用輔助",
      "Utils", "日付、正規表現、数値、文字列、デバイス、UI、コレクション、画像と共通ヘルパー",
      "Utils", "날짜, 정규식, 숫자, 문자열, 기기, UI, 컬렉션, 이미지 및 공통 헬퍼",
      "Utils", "Fecha, regex, número, cadena, dispositivo, UI, colección, imagen y helpers comunes",
      "Utils", "Date, regex, nombre, chaîne, appareil, UI, collection, image et helpers communs",
      "Utils", "Datum, Regex, Zahl, String, Gerät, UI, Collection, Bild und Common Helpers",
      "Utils", "Data, regex, número, string, dispositivo, UI, coleção, imagem e helpers comuns",
      "Utils", "تاريخ وتعبيرات وعدد وسلسلة وجهاز وUI ومجموعة وصورة ومساعدات",
      "Utils", "Date, regex, number, string, device, UI, collection, image and common helpers")

# fmt: on
