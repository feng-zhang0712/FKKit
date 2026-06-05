#!/usr/bin/env python3
"""Generate FKCoreKit and FKUIKit Localizable.strings for 11 BCP-47 languages."""

from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from i18n_extensions import FKCORE_EXT, FKUI_EXT

ROOT = Path(__file__).resolve().parents[1]
LANGS = ["en", "zh-Hans", "zh-Hant", "ja", "ko", "es", "fr", "de", "pt-BR", "ar", "ru"]

# fmt: off
FKCORE = {
    "fkcore.common.ok": {
        "en": "OK", "zh-Hans": "确定", "zh-Hant": "確定", "ja": "OK", "ko": "확인",
        "es": "Aceptar", "fr": "OK", "de": "OK", "pt-BR": "OK", "ar": "موافق", "ru": "OK",
    },
    "fkcore.common.cancel": {
        "en": "Cancel", "zh-Hans": "取消", "zh-Hant": "取消", "ja": "キャンセル", "ko": "취소",
        "es": "Cancelar", "fr": "Annuler", "de": "Abbrechen", "pt-BR": "Cancelar", "ar": "إلغاء", "ru": "Отмена",
    },
    "fkcore.common.continue": {
        "en": "Continue", "zh-Hans": "继续", "zh-Hant": "繼續", "ja": "続ける", "ko": "계속",
        "es": "Continuar", "fr": "Continuer", "de": "Weiter", "pt-BR": "Continuar", "ar": "متابعة", "ru": "Продолжить",
    },
    "fkcore.common.not_now": {
        "en": "Not now", "zh-Hans": "暂不", "zh-Hant": "暫不", "ja": "後で", "ko": "나중에",
        "es": "Ahora no", "fr": "Pas maintenant", "de": "Nicht jetzt", "pt-BR": "Agora não", "ar": "ليس الآن", "ru": "Не сейчас",
    },
    "fkcore.common.retry": {
        "en": "Retry", "zh-Hans": "重试", "zh-Hant": "重試", "ja": "再試行", "ko": "다시 시도",
        "es": "Reintentar", "fr": "Réessayer", "de": "Erneut versuchen", "pt-BR": "Tentar novamente", "ar": "إعادة المحاولة", "ru": "Повторить",
    },
    "fkcore.common.dismiss": {
        "en": "Dismiss", "zh-Hans": "关闭", "zh-Hant": "關閉", "ja": "閉じる", "ko": "닫기",
        "es": "Cerrar", "fr": "Fermer", "de": "Schließen", "pt-BR": "Fechar", "ar": "إغلاق", "ru": "Закрыть",
    },
    "fkcore.common.loading": {
        "en": "Loading…", "zh-Hans": "加载中…", "zh-Hant": "載入中…", "ja": "読み込み中…", "ko": "로딩 중…",
        "es": "Cargando…", "fr": "Chargement…", "de": "Wird geladen…", "pt-BR": "Carregando…", "ar": "جارٍ التحميل…", "ru": "Загрузка…",
    },
    "fkcore.common.error": {
        "en": "Something went wrong", "zh-Hans": "出了点问题", "zh-Hant": "出了點問題", "ja": "問題が発生しました", "ko": "문제가 발생했습니다",
        "es": "Algo salió mal", "fr": "Une erreur s'est produite", "de": "Etwas ist schiefgelaufen", "pt-BR": "Algo deu errado", "ar": "حدث خطأ ما", "ru": "Что-то пошло не так",
    },
    "fkcore.common.settings": {
        "en": "Settings", "zh-Hans": "设置", "zh-Hant": "設定", "ja": "設定", "ko": "설정",
        "es": "Ajustes", "fr": "Réglages", "de": "Einstellungen", "pt-BR": "Ajustes", "ar": "الإعدادات", "ru": "Настройки",
    },
    "fkcore.common.cancelled": {
        "en": "Cancelled", "zh-Hans": "已取消", "zh-Hant": "已取消", "ja": "キャンセルされました", "ko": "취소됨",
        "es": "Cancelado", "fr": "Annulé", "de": "Abgebrochen", "pt-BR": "Cancelado", "ar": "تم الإلغاء", "ru": "Отменено",
    },
    "fkcore.permission.camera.title": {
        "en": "Camera access", "zh-Hans": "相机权限", "zh-Hant": "相機權限", "ja": "カメラへのアクセス", "ko": "카메라 접근",
        "es": "Acceso a la cámara", "fr": "Accès à la caméra", "de": "Kamerazugriff", "pt-BR": "Acesso à câmera", "ar": "الوصول إلى الكاميرا", "ru": "Доступ к камере",
    },
    "fkcore.permission.camera.message": {
        "en": "Allow camera access to take photos and scan codes.",
        "zh-Hans": "允许访问相机以拍照和扫码。", "zh-Hant": "允許存取相機以拍照和掃碼。", "ja": "写真撮影やコード読み取りのためにカメラへのアクセスを許可してください。",
        "ko": "사진 촬영 및 코드 스캔을 위해 카메라 접근을 허용하세요.", "es": "Permite el acceso a la cámara para tomar fotos y escanear códigos.",
        "fr": "Autorisez l'accès à la caméra pour prendre des photos et scanner des codes.", "de": "Erlauben Sie Kamerazugriff zum Fotografieren und Scannen.",
        "pt-BR": "Permita o acesso à câmera para tirar fotos e escanear códigos.", "ar": "اسمح بالوصول إلى الكاميرا لالتقاط الصور ومسح الرموز.", "ru": "Разрешите доступ к камере для съёмки и сканирования кодов.",
    },
    "fkcore.permission.photo.title": {
        "en": "Photo library access", "zh-Hans": "相册权限", "zh-Hant": "相簿權限", "ja": "フォトライブラリへのアクセス", "ko": "사진 라이브러리 접근",
        "es": "Acceso a fotos", "fr": "Accès aux photos", "de": "Fotobibliothek-Zugriff", "pt-BR": "Acesso às fotos", "ar": "الوصول إلى مكتبة الصور", "ru": "Доступ к фото",
    },
    "fkcore.permission.photo.message": {
        "en": "Allow access to choose and save photos.",
        "zh-Hans": "允许访问以选择和保存照片。", "zh-Hant": "允許存取以選擇和儲存照片。", "ja": "写真の選択と保存のためにアクセスを許可してください。",
        "ko": "사진을 선택하고 저장하려면 접근을 허용하세요.", "es": "Permite el acceso para elegir y guardar fotos.",
        "fr": "Autorisez l'accès pour choisir et enregistrer des photos.", "de": "Erlauben Sie Zugriff zum Auswählen und Speichern von Fotos.",
        "pt-BR": "Permita o acesso para escolher e salvar fotos.", "ar": "اسمح بالوصول لاختيار الصور وحفظها.", "ru": "Разрешите доступ для выбора и сохранения фото.",
    },
    "fkcore.permission.location.title": {
        "en": "Location access", "zh-Hans": "位置权限", "zh-Hant": "位置權限", "ja": "位置情報へのアクセス", "ko": "위치 접근",
        "es": "Acceso a la ubicación", "fr": "Accès à la localisation", "de": "Standortzugriff", "pt-BR": "Acesso à localização", "ar": "الوصول إلى الموقع", "ru": "Доступ к геолокации",
    },
    "fkcore.permission.location.message": {
        "en": "Allow location access for nearby features.",
        "zh-Hans": "允许位置访问以使用附近功能。", "zh-Hant": "允許位置存取以使用附近功能。", "ja": "近くの機能のために位置情報へのアクセスを許可してください。",
        "ko": "주변 기능을 위해 위치 접근을 허용하세요.", "es": "Permite el acceso a la ubicación para funciones cercanas.",
        "fr": "Autorisez l'accès à la localisation pour les fonctionnalités à proximité.", "de": "Erlauben Sie Standortzugriff für Funktionen in der Nähe.",
        "pt-BR": "Permita o acesso à localização para recursos próximos.", "ar": "اسمح بالوصول إلى الموقع للميزات القريبة.", "ru": "Разрешите доступ к геолокации для функций рядом с вами.",
    },
    "fkcore.permission.microphone.title": {
        "en": "Microphone access", "zh-Hans": "麦克风权限", "zh-Hant": "麥克風權限", "ja": "マイクへのアクセス", "ko": "마이크 접근",
        "es": "Acceso al micrófono", "fr": "Accès au microphone", "de": "Mikrofonzugriff", "pt-BR": "Acesso ao microfone", "ar": "الوصول إلى الميكروفون", "ru": "Доступ к микрофону",
    },
    "fkcore.permission.microphone.message": {
        "en": "Allow microphone access for audio recording.",
        "zh-Hans": "允许麦克风访问以录制音频。", "zh-Hant": "允許麥克風存取以錄製音訊。", "ja": "音声録音のためにマイクへのアクセスを許可してください。",
        "ko": "오디오 녹음을 위해 마이크 접근을 허용하세요.", "es": "Permite el acceso al micrófono para grabar audio.",
        "fr": "Autorisez l'accès au microphone pour l'enregistrement audio.", "de": "Erlauben Sie Mikrofonzugriff für Audioaufnahmen.",
        "pt-BR": "Permita o acesso ao microfone para gravação de áudio.", "ar": "اسمح بالوصول إلى الميكروفون لتسجيل الصوت.", "ru": "Разрешите доступ к микрофону для записи аудио.",
    },
    "fkcore.permission.notifications.title": {
        "en": "Notifications", "zh-Hans": "通知", "zh-Hant": "通知", "ja": "通知", "ko": "알림",
        "es": "Notificaciones", "fr": "Notifications", "de": "Mitteilungen", "pt-BR": "Notificações", "ar": "الإشعارات", "ru": "Уведомления",
    },
    "fkcore.permission.notifications.message": {
        "en": "Allow notifications to stay informed.",
        "zh-Hans": "允许通知以获取最新信息。", "zh-Hant": "允許通知以取得最新資訊。", "ja": "最新情報を受け取るために通知を許可してください。",
        "ko": "최신 정보를 받으려면 알림을 허용하세요.", "es": "Permite las notificaciones para mantenerte informado.",
        "fr": "Autorisez les notifications pour rester informé.", "de": "Erlauben Sie Mitteilungen, um informiert zu bleiben.",
        "pt-BR": "Permita notificações para se manter informado.", "ar": "اسمح بالإشعارات للبقاء على اطلاع.", "ru": "Разрешите уведомления, чтобы быть в курсе.",
    },
    "fkcore.permission.tracking.title": {
        "en": "Activity tracking", "zh-Hans": "活动跟踪", "zh-Hant": "活動追蹤", "ja": "アクティビティ追跡", "ko": "활동 추적",
        "es": "Seguimiento de actividad", "fr": "Suivi d'activité", "de": "Aktivitätsverfolgung", "pt-BR": "Rastreamento de atividade", "ar": "تتبع النشاط", "ru": "Отслеживание активности",
    },
    "fkcore.permission.tracking.message": {
        "en": "Allow tracking to improve your experience.",
        "zh-Hans": "允许跟踪以改善您的体验。", "zh-Hant": "允許追蹤以改善您的體驗。", "ja": "体験向上のために追跡を許可してください。",
        "ko": "더 나은 경험을 위해 추적을 허용하세요.", "es": "Permite el seguimiento para mejorar tu experiencia.",
        "fr": "Autorisez le suivi pour améliorer votre expérience.", "de": "Erlauben Sie Tracking zur Verbesserung Ihrer Erfahrung.",
        "pt-BR": "Permita rastreamento para melhorar sua experiência.", "ar": "اسمح بالتتبع لتحسين تجربتك.", "ru": "Разрешите отслеживание для улучшения вашего опыта.",
    },
    "fkcore.network.error.invalid_url": {
        "en": "Invalid URL.", "zh-Hans": "无效的 URL。", "zh-Hant": "無效的 URL。", "ja": "無効な URL です。", "ko": "잘못된 URL입니다.",
        "es": "URL no válida.", "fr": "URL non valide.", "de": "Ungültige URL.", "pt-BR": "URL inválida.", "ar": "عنوان URL غير صالح.", "ru": "Недопустимый URL.",
    },
    "fkcore.network.error.invalid_response": {
        "en": "Invalid HTTP response.", "zh-Hans": "无效的 HTTP 响应。", "zh-Hant": "無效的 HTTP 回應。", "ja": "無効な HTTP 応答です。", "ko": "잘못된 HTTP 응답입니다.",
        "es": "Respuesta HTTP no válida.", "fr": "Réponse HTTP non valide.", "de": "Ungültige HTTP-Antwort.", "pt-BR": "Resposta HTTP inválida.", "ar": "استجابة HTTP غير صالحة.", "ru": "Недопустимый HTTP-ответ.",
    },
    "fkcore.network.error.request_cancelled": {
        "en": "Request was cancelled.", "zh-Hans": "请求已取消。", "zh-Hant": "請求已取消。", "ja": "リクエストがキャンセルされました。", "ko": "요청이 취소되었습니다.",
        "es": "La solicitud fue cancelada.", "fr": "La requête a été annulée.", "de": "Anfrage wurde abgebrochen.", "pt-BR": "A solicitação foi cancelada.", "ar": "تم إلغاء الطلب.", "ru": "Запрос был отменён.",
    },
    "fkcore.network.error.no_data": {
        "en": "No data returned from server.", "zh-Hans": "服务器未返回数据。", "zh-Hant": "伺服器未返回資料。", "ja": "サーバーからデータが返されませんでした。", "ko": "서버에서 데이터가 반환되지 않았습니다.",
        "es": "El servidor no devolvió datos.", "fr": "Aucune donnée renvoyée par le serveur.", "de": "Keine Daten vom Server erhalten.", "pt-BR": "Nenhum dado retornado do servidor.", "ar": "لم يُرجع الخادم أي بيانات.", "ru": "Сервер не вернул данные.",
    },
    "fkcore.network.error.decoding_failed": {
        "en": "Failed to decode response: %@",
        "zh-Hans": "解析响应失败：%@", "zh-Hant": "解析回應失敗：%@", "ja": "応答のデコードに失敗しました：%@", "ko": "응답 디코딩 실패: %@",
        "es": "Error al decodificar la respuesta: %@", "fr": "Échec du décodage de la réponse : %@", "de": "Antwort konnte nicht decodiert werden: %@",
        "pt-BR": "Falha ao decodificar a resposta: %@", "ar": "فشل فك ترميز الاستجابة: %@", "ru": "Не удалось декодировать ответ: %@",
    },
    "fkcore.network.error.server_error": {
        "en": "Server error (%d): %@",
        "zh-Hans": "服务器错误（%d）：%@", "zh-Hant": "伺服器錯誤（%d）：%@", "ja": "サーバーエラー（%d）：%@", "ko": "서버 오류 (%d): %@",
        "es": "Error del servidor (%d): %@", "fr": "Erreur serveur (%d) : %@", "de": "Serverfehler (%d): %@",
        "pt-BR": "Erro do servidor (%d): %@", "ar": "خطأ في الخادم (%d): %@", "ru": "Ошибка сервера (%d): %@",
    },
    "fkcore.network.error.unknown_server_message": {
        "en": "Unknown error", "zh-Hans": "未知错误", "zh-Hant": "未知錯誤", "ja": "不明なエラー", "ko": "알 수 없는 오류",
        "es": "Error desconocido", "fr": "Erreur inconnue", "de": "Unbekannter Fehler", "pt-BR": "Erro desconhecido", "ar": "خطأ غير معروف", "ru": "Неизвестная ошибка",
    },
    "fkcore.network.error.business_error": {
        "en": "Business error (%d): %@",
        "zh-Hans": "业务错误（%d）：%@", "zh-Hant": "業務錯誤（%d）：%@", "ja": "ビジネスエラー（%d）：%@", "ko": "비즈니스 오류 (%d): %@",
        "es": "Error de negocio (%d): %@", "fr": "Erreur métier (%d) : %@", "de": "Geschäftsfehler (%d): %@",
        "pt-BR": "Erro de negócio (%d): %@", "ar": "خطأ في العمل (%d): %@", "ru": "Бизнес-ошибка (%d): %@",
    },
    "fkcore.network.error.ssl_validation_failed": {
        "en": "SSL validation failed.", "zh-Hans": "SSL 验证失败。", "zh-Hant": "SSL 驗證失敗。", "ja": "SSL 検証に失敗しました。", "ko": "SSL 검증에 실패했습니다.",
        "es": "Error en la validación SSL.", "fr": "Échec de la validation SSL.", "de": "SSL-Validierung fehlgeschlagen.", "pt-BR": "Falha na validação SSL.", "ar": "فشل التحقق من SSL.", "ru": "Проверка SSL не удалась.",
    },
    "fkcore.network.error.offline": {
        "en": "No network connection.", "zh-Hans": "无网络连接。", "zh-Hant": "無網路連線。", "ja": "ネットワーク接続がありません。", "ko": "네트워크 연결이 없습니다.",
        "es": "Sin conexión de red.", "fr": "Aucune connexion réseau.", "de": "Keine Netzwerkverbindung.", "pt-BR": "Sem conexão de rede.", "ar": "لا يوجد اتصال بالشبكة.", "ru": "Нет сетевого подключения.",
    },
    "fkcore.network.error.token_refresh_failed": {
        "en": "Token refresh failed.", "zh-Hans": "令牌刷新失败。", "zh-Hant": "權杖重新整理失敗。", "ja": "トークンの更新に失敗しました。", "ko": "토큰 갱신에 실패했습니다.",
        "es": "Error al actualizar el token.", "fr": "Échec du rafraîchissement du jeton.", "de": "Token-Aktualisierung fehlgeschlagen.", "pt-BR": "Falha ao atualizar o token.", "ar": "فشل تحديث الرمز.", "ru": "Не удалось обновить токен.",
    },
    "fkcore.network.error.signing_failed": {
        "en": "Request signing failed.", "zh-Hans": "请求签名失败。", "zh-Hant": "請求簽名失敗。", "ja": "リクエストの署名に失敗しました。", "ko": "요청 서명에 실패했습니다.",
        "es": "Error al firmar la solicitud.", "fr": "Échec de la signature de la requête.", "de": "Anfrage-Signierung fehlgeschlagen.", "pt-BR": "Falha ao assinar a solicitação.", "ar": "فشل توقيع الطلب.", "ru": "Не удалось подписать запрос.",
    },
    "fkcore.network.error.encryption_failed": {
        "en": "Parameter encryption failed.", "zh-Hans": "参数加密失败。", "zh-Hant": "參數加密失敗。", "ja": "パラメータの暗号化に失敗しました。", "ko": "매개변수 암호화에 실패했습니다.",
        "es": "Error al cifrar los parámetros.", "fr": "Échec du chiffrement des paramètres.", "de": "Parameterverschlüsselung fehlgeschlagen.", "pt-BR": "Falha ao criptografar parâmetros.", "ar": "فشل تشفير المعلمات.", "ru": "Не удалось зашифровать параметры.",
    },
    "fkcore.network.error.request_deduplicated": {
        "en": "Request deduplicated.", "zh-Hans": "请求已去重。", "zh-Hant": "請求已去重。", "ja": "リクエストは重複排除されました。", "ko": "요청이 중복 제거되었습니다.",
        "es": "Solicitud deduplicada.", "fr": "Requête dédupliquée.", "de": "Anfrage dedupliziert.", "pt-BR": "Solicitação deduplicada.", "ar": "تم إزالة تكرار الطلب.", "ru": "Запрос дедуплицирован.",
    },
    "fkcore.network.error.client_released": {
        "en": "Client released before completion.", "zh-Hans": "客户端在完成前已释放。", "zh-Hant": "用戶端在完成前已釋放。", "ja": "完了前にクライアントが解放されました。", "ko": "완료 전에 클라이언트가 해제되었습니다.",
        "es": "Cliente liberado antes de completar.", "fr": "Client libéré avant la fin.", "de": "Client vor Abschluss freigegeben.", "pt-BR": "Cliente liberado antes da conclusão.", "ar": "تم تحرير العميل قبل الاكتمال.", "ru": "Клиент освобождён до завершения.",
    },
    "fkcore.network.offline": {
        "en": "You are offline", "zh-Hans": "您已离线", "zh-Hant": "您已離線", "ja": "オフラインです", "ko": "오프라인 상태입니다",
        "es": "Estás sin conexión", "fr": "Vous êtes hors ligne", "de": "Sie sind offline", "pt-BR": "Você está offline", "ar": "أنت غير متصل", "ru": "Вы не в сети",
    },
    "fkcore.network.timeout": {
        "en": "Request timed out", "zh-Hans": "请求超时", "zh-Hant": "請求逾時", "ja": "リクエストがタイムアウトしました", "ko": "요청 시간이 초과되었습니다",
        "es": "La solicitud expiró", "fr": "Délai de requête dépassé", "de": "Anfrage-Zeitüberschreitung", "pt-BR": "Tempo da solicitação esgotado", "ar": "انتهت مهلة الطلب", "ru": "Время запроса истекло",
    },
    "fkcore.network.server_error": {
        "en": "Server error. Please try again later.", "zh-Hans": "服务器错误，请稍后重试。", "zh-Hant": "伺服器錯誤，請稍後重試。", "ja": "サーバーエラーです。後でもう一度お試しください。", "ko": "서버 오류입니다. 나중에 다시 시도하세요.",
        "es": "Error del servidor. Inténtalo más tarde.", "fr": "Erreur serveur. Réessayez plus tard.", "de": "Serverfehler. Bitte später erneut versuchen.", "pt-BR": "Erro do servidor. Tente novamente mais tarde.", "ar": "خطأ في الخادم. يرجى المحاولة لاحقًا.", "ru": "Ошибка сервера. Попробуйте позже.",
    },
    "fkcore.network.unauthorized": {
        "en": "Session expired. Please sign in again.", "zh-Hans": "会话已过期，请重新登录。", "zh-Hant": "工作階段已過期，請重新登入。", "ja": "セッションの有効期限が切れました。再度サインインしてください。", "ko": "세션이 만료되었습니다. 다시 로그인하세요.",
        "es": "Sesión expirada. Inicia sesión de nuevo.", "fr": "Session expirée. Veuillez vous reconnecter.", "de": "Sitzung abgelaufen. Bitte erneut anmelden.", "pt-BR": "Sessão expirada. Faça login novamente.", "ar": "انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.", "ru": "Сессия истекла. Войдите снова.",
    },
    "fkcore.storage.error.not_found": {
        "en": "No stored value for key.", "zh-Hans": "未找到存储的值。", "zh-Hant": "未找到儲存的值。", "ja": "キーに保存された値がありません。", "ko": "키에 저장된 값이 없습니다.",
        "es": "No hay valor almacenado para la clave.", "fr": "Aucune valeur stockée pour la clé.", "de": "Kein gespeicherter Wert für den Schlüssel.", "pt-BR": "Nenhum valor armazenado para a chave.", "ar": "لا توجد قيمة مخزنة للمفتاح.", "ru": "Нет сохранённого значения для ключа.",
    },
    "fkcore.storage.error.encoding_failed": {
        "en": "Encoding failed: %@", "zh-Hans": "编码失败：%@", "zh-Hant": "編碼失敗：%@", "ja": "エンコードに失敗しました：%@", "ko": "인코딩 실패: %@",
        "es": "Error de codificación: %@", "fr": "Échec de l'encodage : %@", "de": "Kodierung fehlgeschlagen: %@", "pt-BR": "Falha na codificação: %@", "ar": "فشل الترميز: %@", "ru": "Ошибка кодирования: %@",
    },
    "fkcore.storage.error.decoding_failed": {
        "en": "Decoding failed: %@", "zh-Hans": "解码失败：%@", "zh-Hant": "解碼失敗：%@", "ja": "デコードに失敗しました：%@", "ko": "디코딩 실패: %@",
        "es": "Error de decodificación: %@", "fr": "Échec du décodage : %@", "de": "Dekodierung fehlgeschlagen: %@", "pt-BR": "Falha na decodificação: %@", "ar": "فشل فك الترميز: %@", "ru": "Ошибка декодирования: %@",
    },
    "fkcore.storage.error.keychain_failed": {
        "en": "Keychain error (status %d).", "zh-Hans": "钥匙串错误（状态 %d）。", "zh-Hant": "鑰匙圈錯誤（狀態 %d）。", "ja": "キーチェーンエラー（ステータス %d）。", "ko": "키체인 오류 (상태 %d).",
        "es": "Error de llavero (estado %d).", "fr": "Erreur de trousseau (statut %d).", "de": "Schlüsselbundfehler (Status %d).", "pt-BR": "Erro de keychain (status %d).", "ar": "خطأ في Keychain (الحالة %d).", "ru": "Ошибка Keychain (статус %d).",
    },
    "fkcore.storage.error.file_system_failed": {
        "en": "File system error: %@", "zh-Hans": "文件系统错误：%@", "zh-Hant": "檔案系統錯誤：%@", "ja": "ファイルシステムエラー：%@", "ko": "파일 시스템 오류: %@",
        "es": "Error del sistema de archivos: %@", "fr": "Erreur du système de fichiers : %@", "de": "Dateisystemfehler: %@", "pt-BR": "Erro do sistema de arquivos: %@", "ar": "خطأ في نظام الملفات: %@", "ru": "Ошибка файловой системы: %@",
    },
    "fkcore.storage.error.invalid_key": {
        "en": "Invalid storage key.", "zh-Hans": "无效的存储键。", "zh-Hant": "無效的儲存鍵。", "ja": "無効なストレージキーです。", "ko": "잘못된 저장 키입니다.",
        "es": "Clave de almacenamiento no válida.", "fr": "Clé de stockage non valide.", "de": "Ungültiger Speicherschlüssel.", "pt-BR": "Chave de armazenamento inválida.", "ar": "مفتاح تخزين غير صالح.", "ru": "Недопустимый ключ хранения.",
    },
    "fkcore.storage.error.unsupported": {
        "en": "Operation not supported.", "zh-Hans": "不支持的操作。", "zh-Hant": "不支援的操作。", "ja": "サポートされていない操作です。", "ko": "지원되지 않는 작업입니다.",
        "es": "Operación no compatible.", "fr": "Opération non prise en charge.", "de": "Vorgang nicht unterstützt.", "pt-BR": "Operação não suportada.", "ar": "العملية غير مدعومة.", "ru": "Операция не поддерживается.",
    },
    "fkcore.storage.error": {
        "en": "Could not save data", "zh-Hans": "无法保存数据", "zh-Hant": "無法儲存資料", "ja": "データを保存できませんでした", "ko": "데이터를 저장할 수 없습니다",
        "es": "No se pudieron guardar los datos", "fr": "Impossible d'enregistrer les données", "de": "Daten konnten nicht gespeichert werden", "pt-BR": "Não foi possível salvar os dados", "ar": "تعذر حفظ البيانات", "ru": "Не удалось сохранить данные",
    },
    "fkcore.security.error": {
        "en": "Security operation failed", "zh-Hans": "安全操作失败", "zh-Hant": "安全操作失敗", "ja": "セキュリティ操作に失敗しました", "ko": "보안 작업에 실패했습니다",
        "es": "Error en la operación de seguridad", "fr": "Échec de l'opération de sécurité", "de": "Sicherheitsvorgang fehlgeschlagen", "pt-BR": "Falha na operação de segurança", "ar": "فشلت عملية الأمان", "ru": "Ошибка операции безопасности",
    },
    "fkcore.business.version.update_available.title": {
        "en": "Update Available", "zh-Hans": "有可用更新", "zh-Hant": "有可用更新", "ja": "アップデートがあります", "ko": "업데이트 가능",
        "es": "Actualización disponible", "fr": "Mise à jour disponible", "de": "Update verfügbar", "pt-BR": "Atualização disponível", "ar": "يتوفر تحديث", "ru": "Доступно обновление",
    },
    "fkcore.business.version.update_available.action_update": {
        "en": "Update", "zh-Hans": "更新", "zh-Hant": "更新", "ja": "更新", "ko": "업데이트",
        "es": "Actualizar", "fr": "Mettre à jour", "de": "Aktualisieren", "pt-BR": "Atualizar", "ar": "تحديث", "ru": "Обновить",
    },
    "fkcore.business.version.update_available.action_later": {
        "en": "Later", "zh-Hans": "稍后", "zh-Hant": "稍後", "ja": "後で", "ko": "나중에",
        "es": "Más tarde", "fr": "Plus tard", "de": "Später", "pt-BR": "Depois", "ar": "لاحقًا", "ru": "Позже",
    },
    "fkcore.business.version.update_available.latest_version": {
        "en": "Latest version: %@", "zh-Hans": "最新版本：%@", "zh-Hant": "最新版本：%@", "ja": "最新バージョン：%@", "ko": "최신 버전: %@",
        "es": "Última versión: %@", "fr": "Dernière version : %@", "de": "Neueste Version: %@", "pt-BR": "Versão mais recente: %@", "ar": "أحدث إصدار: %@", "ru": "Последняя версия: %@",
    },
    "fkcore.business.version.update_available.force_message": {
        "en": "This update is required to continue.", "zh-Hans": "需要此更新才能继续使用。", "zh-Hant": "需要此更新才能繼續使用。", "ja": "続行するにはこのアップデートが必要です。", "ko": "계속하려면 이 업데이트가 필요합니다.",
        "es": "Esta actualización es necesaria para continuar.", "fr": "Cette mise à jour est requise pour continuer.", "de": "Dieses Update ist erforderlich, um fortzufahren.", "pt-BR": "Esta atualização é necessária para continuar.", "ar": "هذا التحديث مطلوب للمتابعة.", "ru": "Это обновление необходимо для продолжения.",
    },
    "fkcore.business.time.just_now": {
        "en": "Just now", "zh-Hans": "刚刚", "zh-Hant": "剛剛", "ja": "たった今", "ko": "방금",
        "es": "Justo ahora", "fr": "À l'instant", "de": "Gerade eben", "pt-BR": "Agora mesmo", "ar": "الآن", "ru": "Только что",
    },
    "fkcore.business.time.seconds_ago": {
        "en": "%ds ago", "zh-Hans": "%d 秒前", "zh-Hant": "%d 秒前", "ja": "%d 秒前", "ko": "%d초 전",
        "es": "Hace %d s", "fr": "Il y a %d s", "de": "Vor %d s", "pt-BR": "Há %d s", "ar": "منذ %d ث", "ru": "%d с назад",
    },
    "fkcore.business.time.minutes_ago": {
        "en": "%dm ago", "zh-Hans": "%d 分钟前", "zh-Hant": "%d 分鐘前", "ja": "%d 分前", "ko": "%d분 전",
        "es": "Hace %d min", "fr": "Il y a %d min", "de": "Vor %d Min", "pt-BR": "Há %d min", "ar": "منذ %d د", "ru": "%d мин назад",
    },
    "fkcore.business.time.today_at": {
        "en": "Today %@", "zh-Hans": "今天 %@", "zh-Hant": "今天 %@", "ja": "今日 %@", "ko": "오늘 %@",
        "es": "Hoy %@", "fr": "Aujourd'hui %@", "de": "Heute %@", "pt-BR": "Hoje %@", "ar": "اليوم %@", "ru": "Сегодня %@",
    },
    "fkcore.business.time.yesterday_at": {
        "en": "Yesterday %@", "zh-Hans": "昨天 %@", "zh-Hant": "昨天 %@", "ja": "昨日 %@", "ko": "어제 %@",
        "es": "Ayer %@", "fr": "Hier %@", "de": "Gestern %@", "pt-BR": "Ontem %@", "ar": "أمس %@", "ru": "Вчера %@",
    },
    "fkcore.utils.time.just_now": {
        "en": "just now", "zh-Hans": "刚刚", "zh-Hant": "剛剛", "ja": "たった今", "ko": "방금",
        "es": "justo ahora", "fr": "à l'instant", "de": "gerade eben", "pt-BR": "agora mesmo", "ar": "الآن", "ru": "только что",
    },
    "fkcore.utils.time.seconds_ago": {
        "en": "%d seconds ago", "zh-Hans": "%d 秒前", "zh-Hant": "%d 秒前", "ja": "%d 秒前", "ko": "%d초 전",
        "es": "Hace %d segundos", "fr": "Il y a %d secondes", "de": "Vor %d Sekunden", "pt-BR": "Há %d segundos", "ar": "منذ %d ثانية", "ru": "%d секунд назад",
    },
    "fkcore.utils.time.minutes_ago": {
        "en": "%d minutes ago", "zh-Hans": "%d 分钟前", "zh-Hant": "%d 分鐘前", "ja": "%d 分前", "ko": "%d분 전",
        "es": "Hace %d minutos", "fr": "Il y a %d minutes", "de": "Vor %d Minuten", "pt-BR": "Há %d minutos", "ar": "منذ %d دقيقة", "ru": "%d минут назад",
    },
    "fkcore.utils.time.hours_ago": {
        "en": "%d hours ago", "zh-Hans": "%d 小时前", "zh-Hant": "%d 小時前", "ja": "%d 時間前", "ko": "%d시간 전",
        "es": "Hace %d horas", "fr": "Il y a %d heures", "de": "Vor %d Stunden", "pt-BR": "Há %d horas", "ar": "منذ %d ساعة", "ru": "%d часов назад",
    },
    "fkcore.utils.time.yesterday": {
        "en": "yesterday", "zh-Hans": "昨天", "zh-Hant": "昨天", "ja": "昨日", "ko": "어제",
        "es": "ayer", "fr": "hier", "de": "gestern", "pt-BR": "ontem", "ar": "أمس", "ru": "вчера",
    },
    "fkcore.utils.time.day_before_yesterday": {
        "en": "the day before yesterday", "zh-Hans": "前天", "zh-Hant": "前天", "ja": "一昨日", "ko": "그저께",
        "es": "anteayer", "fr": "avant-hier", "de": "vorgestern", "pt-BR": "anteontem", "ar": "أول أمس", "ru": "позавчера",
    },
}

FKUI = {
    "fkuikit.common.ok": FKCORE["fkcore.common.ok"],
    "fkuikit.common.cancel": FKCORE["fkcore.common.cancel"],
    "fkuikit.common.retry": FKCORE["fkcore.common.retry"],
    "fkuikit.common.loading": FKCORE["fkcore.common.loading"],
    "fkuikit.common.cancelled": FKCORE["fkcore.common.cancelled"],
    "fkuikit.common.dismiss": FKCORE["fkcore.common.dismiss"],
    "fkuikit.refresh.pull": {
        "en": "Pull to refresh", "zh-Hans": "下拉刷新", "zh-Hant": "下拉重新整理", "ja": "引っ張って更新", "ko": "당겨서 새로고침",
        "es": "Desliza para actualizar", "fr": "Tirer pour actualiser", "de": "Zum Aktualisieren ziehen", "pt-BR": "Puxe para atualizar", "ar": "اسحب للتحديث", "ru": "Потяните для обновления",
    },
    "fkuikit.refresh.release": {
        "en": "Release to refresh", "zh-Hans": "松开刷新", "zh-Hant": "鬆開重新整理", "ja": "離して更新", "ko": "놓아서 새로고침",
        "es": "Suelta para actualizar", "fr": "Relâcher pour actualiser", "de": "Loslassen zum Aktualisieren", "pt-BR": "Solte para atualizar", "ar": "أفلت للتحديث", "ru": "Отпустите для обновления",
    },
    "fkuikit.refresh.header.loading": FKCORE["fkcore.common.loading"],
    "fkuikit.refresh.header.finished": {
        "en": "Up to date", "zh-Hans": "已是最新", "zh-Hant": "已是最新", "ja": "最新です", "ko": "최신 상태",
        "es": "Actualizado", "fr": "À jour", "de": "Aktuell", "pt-BR": "Atualizado", "ar": "محدّث", "ru": "Актуально",
    },
    "fkuikit.refresh.header.empty": {
        "en": "No content", "zh-Hans": "暂无内容", "zh-Hant": "暫無內容", "ja": "コンテンツがありません", "ko": "콘텐츠 없음",
        "es": "Sin contenido", "fr": "Aucun contenu", "de": "Kein Inhalt", "pt-BR": "Sem conteúdo", "ar": "لا يوجد محتوى", "ru": "Нет содержимого",
    },
    "fkuikit.refresh.header.failed": {
        "en": "Couldn't refresh", "zh-Hans": "刷新失败", "zh-Hant": "重新整理失敗", "ja": "更新できませんでした", "ko": "새로고침 실패",
        "es": "No se pudo actualizar", "fr": "Actualisation impossible", "de": "Aktualisierung fehlgeschlagen", "pt-BR": "Não foi possível atualizar", "ar": "تعذر التحديث", "ru": "Не удалось обновить",
    },
    "fkuikit.refresh.footer.loading": FKCORE["fkcore.common.loading"],
    "fkuikit.refresh.footer.finished": {
        "en": "Loaded", "zh-Hans": "已加载", "zh-Hant": "已載入", "ja": "読み込み完了", "ko": "로드됨",
        "es": "Cargado", "fr": "Chargé", "de": "Geladen", "pt-BR": "Carregado", "ar": "تم التحميل", "ru": "Загружено",
    },
    "fkuikit.refresh.footer.no_more": {
        "en": "No more data", "zh-Hans": "没有更多数据", "zh-Hant": "沒有更多資料", "ja": "これ以上データはありません", "ko": "더 이상 데이터 없음",
        "es": "No hay más datos", "fr": "Plus de données", "de": "Keine weiteren Daten", "pt-BR": "Sem mais dados", "ar": "لا مزيد من البيانات", "ru": "Больше нет данных",
    },
    "fkuikit.refresh.footer.failed": {
        "en": "Couldn't load", "zh-Hans": "加载失败", "zh-Hant": "載入失敗", "ja": "読み込めませんでした", "ko": "로드 실패",
        "es": "No se pudo cargar", "fr": "Chargement impossible", "de": "Laden fehlgeschlagen", "pt-BR": "Não foi possível carregar", "ar": "تعذر التحميل", "ru": "Не удалось загрузить",
    },
    "fkuikit.refresh.footer.tap_retry": {
        "en": "Tap to retry", "zh-Hans": "点击重试", "zh-Hant": "點擊重試", "ja": "タップして再試行", "ko": "탭하여 다시 시도",
        "es": "Toca para reintentar", "fr": "Appuyer pour réessayer", "de": "Tippen zum Wiederholen", "pt-BR": "Toque para tentar novamente", "ar": "اضغط لإعادة المحاولة", "ru": "Нажмите для повтора",
    },
    "fkuikit.button.loading": {
        "en": "Loading", "zh-Hans": "加载中", "zh-Hant": "載入中", "ja": "読み込み中", "ko": "로딩 중",
        "es": "Cargando", "fr": "Chargement", "de": "Wird geladen", "pt-BR": "Carregando", "ar": "جارٍ التحميل", "ru": "Загрузка",
    },
    "fkuikit.button.success": {
        "en": "Success", "zh-Hans": "成功", "zh-Hant": "成功", "ja": "成功", "ko": "성공",
        "es": "Éxito", "fr": "Succès", "de": "Erfolg", "pt-BR": "Sucesso", "ar": "نجاح", "ru": "Успех",
    },
    "fkuikit.button.failed": {
        "en": "Failed", "zh-Hans": "失败", "zh-Hant": "失敗", "ja": "失敗", "ko": "실패",
        "es": "Error", "fr": "Échec", "de": "Fehlgeschlagen", "pt-BR": "Falhou", "ar": "فشل", "ru": "Ошибка",
    },
    "fkuikit.toast.dismiss": FKCORE["fkcore.common.dismiss"],
    "fkuikit.sheet.dismiss_label": FKCORE["fkcore.common.dismiss"],
    "fkuikit.sheet.dismiss_action": FKCORE["fkcore.common.dismiss"],
    "fkuikit.sheet.grabber_label": {
        "en": "Handle", "zh-Hans": "拖动手柄", "zh-Hant": "拖動手柄", "ja": "ハンドル", "ko": "핸들",
        "es": "Asa", "fr": "Poignée", "de": "Griff", "pt-BR": "Alça", "ar": "مقبض", "ru": "Ручка",
    },
    "fkuikit.sheet.grabber_hint": {
        "en": "Swipe up or down to adjust.", "zh-Hans": "上下滑动以调整。", "zh-Hant": "上下滑動以調整。", "ja": "上下にスワイプして調整します。", "ko": "위아래로 스와이프하여 조절하세요.",
        "es": "Desliza hacia arriba o abajo para ajustar.", "fr": "Balayez vers le haut ou le bas pour ajuster.", "de": "Nach oben oder unten wischen zum Anpassen.", "pt-BR": "Deslize para cima ou para baixo para ajustar.", "ar": "اسحب لأعلى أو لأسفل للتعديل.", "ru": "Проведите вверх или вниз для настройки.",
    },
    "fkuikit.actionsheet.destructive_hint": {
        "en": "This action cannot be undone.", "zh-Hans": "此操作无法撤销。", "zh-Hant": "此操作無法撤銷。", "ja": "この操作は元に戻せません。", "ko": "이 작업은 취소할 수 없습니다.",
        "es": "Esta acción no se puede deshacer.", "fr": "Cette action est irréversible.", "de": "Diese Aktion kann nicht rückgängig gemacht werden.", "pt-BR": "Esta ação não pode ser desfeita.", "ar": "لا يمكن التراجع عن هذا الإجراء.", "ru": "Это действие нельзя отменить.",
    },
    "fkuikit.callout.got_it": {
        "en": "Got it", "zh-Hans": "知道了", "zh-Hant": "知道了", "ja": "了解", "ko": "확인",
        "es": "Entendido", "fr": "Compris", "de": "Verstanden", "pt-BR": "Entendi", "ar": "حسنًا", "ru": "Понятно",
    },
    "fkuikit.callout.popover_content": {
        "en": "Popover content", "zh-Hans": "弹出内容", "zh-Hant": "彈出內容", "ja": "ポップオーバーの内容", "ko": "팝오버 콘텐츠",
        "es": "Contenido del popover", "fr": "Contenu du popover", "de": "Popover-Inhalt", "pt-BR": "Conteúdo do popover", "ar": "محتوى النافذة المنبثقة", "ru": "Содержимое всплывающего окна",
    },
    "fkuikit.callout.close": FKCORE["fkcore.common.dismiss"],
    "fkuikit.rating.accessibility.label": {
        "en": "Rating", "zh-Hans": "评分", "zh-Hant": "評分", "ja": "評価", "ko": "평점",
        "es": "Calificación", "fr": "Note", "de": "Bewertung", "pt-BR": "Avaliação", "ar": "التقييم", "ru": "Оценка",
    },
    "fkuikit.rating.accessibility.adjustable_hint": {
        "en": "Adjustable", "zh-Hans": "可调整", "zh-Hant": "可調整", "ja": "調整可能", "ko": "조절 가능",
        "es": "Ajustable", "fr": "Ajustable", "de": "Einstellbar", "pt-BR": "Ajustável", "ar": "قابل للتعديل", "ru": "Настраиваемый",
    },
    "fkuikit.rating.accessibility.value_format": {
        "en": "%@ out of %@", "zh-Hans": "%@ / %@", "zh-Hant": "%@ / %@", "ja": "%@ / %@", "ko": "%@ / %@",
        "es": "%@ de %@", "fr": "%@ sur %@", "de": "%@ von %@", "pt-BR": "%@ de %@", "ar": "%@ من %@", "ru": "%@ из %@",
    },
    "fkuikit.tabbar.selected": {
        "en": "Selected", "zh-Hans": "已选中", "zh-Hant": "已選中", "ja": "選択済み", "ko": "선택됨",
        "es": "Seleccionado", "fr": "Sélectionné", "de": "Ausgewählt", "pt-BR": "Selecionado", "ar": "محدد", "ru": "Выбрано",
    },
    "fkuikit.tabbar.badge": {
        "en": "Badge", "zh-Hans": "徽章", "zh-Hant": "徽章", "ja": "バッジ", "ko": "배지",
        "es": "Insignia", "fr": "Badge", "de": "Abzeichen", "pt-BR": "Distintivo", "ar": "شارة", "ru": "Значок",
    },
    "fkuikit.tabbar.badge_count": {
        "en": "Badge %lld", "zh-Hans": "徽章 %lld", "zh-Hant": "徽章 %lld", "ja": "バッジ %lld", "ko": "배지 %lld",
        "es": "Insignia %lld", "fr": "Badge %lld", "de": "Abzeichen %lld", "pt-BR": "Distintivo %lld", "ar": "شارة %lld", "ru": "Значок %lld",
    },
    "fkuikit.tabbar.badge_text": {
        "en": "Badge %@", "zh-Hans": "徽章 %@", "zh-Hant": "徽章 %@", "ja": "バッジ %@", "ko": "배지 %@",
        "es": "Insignia %@", "fr": "Badge %@", "de": "Abzeichen %@", "pt-BR": "Distintivo %@", "ar": "شارة %@", "ru": "Значок %@",
    },
    "fkuikit.tabbar.badge_custom": {
        "en": "Custom badge", "zh-Hans": "自定义徽章", "zh-Hant": "自訂徽章", "ja": "カスタムバッジ", "ko": "사용자 지정 배지",
        "es": "Insignia personalizada", "fr": "Badge personnalisé", "de": "Benutzerdefiniertes Abzeichen", "pt-BR": "Distintivo personalizado", "ar": "شارة مخصصة", "ru": "Пользовательский значок",
    },
    "fkuikit.paging.no_pages": {
        "en": "No pages", "zh-Hans": "无页面", "zh-Hant": "無頁面", "ja": "ページがありません", "ko": "페이지 없음",
        "es": "Sin páginas", "fr": "Aucune page", "de": "Keine Seiten", "pt-BR": "Sem páginas", "ar": "لا توجد صفحات", "ru": "Нет страниц",
    },
    "fkuikit.expandable_text.read_more": {
        "en": "Read more", "zh-Hans": "展开", "zh-Hant": "展開", "ja": "続きを読む", "ko": "더 보기",
        "es": "Leer más", "fr": "Lire la suite", "de": "Mehr lesen", "pt-BR": "Ler mais", "ar": "اقرأ المزيد", "ru": "Читать далее",
    },
    "fkuikit.expandable_text.collapse": {
        "en": "Collapse", "zh-Hans": "收起", "zh-Hant": "收起", "ja": "折りたたむ", "ko": "접기",
        "es": "Contraer", "fr": "Réduire", "de": "Einklappen", "pt-BR": "Recolher", "ar": "طي", "ru": "Свернуть",
    },
    "fkuikit.expandable_text.accessibility.expand": {
        "en": "Expand text", "zh-Hans": "展开文本", "zh-Hant": "展開文字", "ja": "テキストを展開", "ko": "텍스트 펼치기",
        "es": "Expandir texto", "fr": "Développer le texte", "de": "Text erweitern", "pt-BR": "Expandir texto", "ar": "توسيع النص", "ru": "Развернуть текст",
    },
    "fkuikit.expandable_text.accessibility.collapse": {
        "en": "Collapse text", "zh-Hans": "收起文本", "zh-Hant": "收起文字", "ja": "テキストを折りたたむ", "ko": "텍스트 접기",
        "es": "Contraer texto", "fr": "Réduire le texte", "de": "Text einklappen", "pt-BR": "Recolher texto", "ar": "طي النص", "ru": "Свернуть текст",
    },
    "fkuikit.expandable_text.accessibility.hint": {
        "en": "Double-tap to toggle text expansion.", "zh-Hans": "双击以切换文本展开。", "zh-Hant": "雙擊以切換文字展開。", "ja": "ダブルタップで展開を切り替えます。", "ko": "두 번 탭하여 텍스트 확장을 전환하세요.",
        "es": "Toca dos veces para alternar la expansión.", "fr": "Double appui pour basculer l'expansion.", "de": "Doppeltippen zum Umschalten.", "pt-BR": "Toque duas vezes para alternar a expansão.", "ar": "اضغط مرتين للتبديل.", "ru": "Дважды нажмите для переключения.",
    },
    "fkuikit.progressbar.in_progress": {
        "en": "In progress", "zh-Hans": "进行中", "zh-Hant": "進行中", "ja": "進行中", "ko": "진행 중",
        "es": "En progreso", "fr": "En cours", "de": "In Bearbeitung", "pt-BR": "Em andamento", "ar": "قيد التقدم", "ru": "В процессе",
    },
    "fkuikit.progressbar.a11y_buffer": {
        "en": "%1$@ progress, %2$@ buffered", "zh-Hans": "%1$@ 进度，%2$@ 已缓冲", "zh-Hant": "%1$@ 進度，%2$@ 已緩衝", "ja": "%1$@ 進捗、%2$@ バッファ済み", "ko": "%1$@ 진행, %2$@ 버퍼됨",
        "es": "%1$@ de progreso, %2$@ en búfer", "fr": "%1$@ de progression, %2$@ en mémoire tampon", "de": "%1$@ Fortschritt, %2$@ gepuffert", "pt-BR": "%1$@ de progresso, %2$@ em buffer", "ar": "%1$@ تقدم، %2$@ مخزن مؤقتًا", "ru": "%1$@ прогресс, %2$@ в буфере",
    },
    "fkuikit.progressbar.a11y_percent": {
        "en": "%lld percent", "zh-Hans": "%lld%%", "zh-Hant": "%lld%%", "ja": "%lld パーセント", "ko": "%lld%%",
        "es": "%lld por ciento", "fr": "%lld pour cent", "de": "%lld Prozent", "pt-BR": "%lld por cento", "ar": "%lld بالمئة", "ru": "%lld процентов",
    },
    "fkuikit.textfield.clear_label": {
        "en": "Clear text", "zh-Hans": "清除文本", "zh-Hant": "清除文字", "ja": "テキストをクリア", "ko": "텍스트 지우기",
        "es": "Borrar texto", "fr": "Effacer le texte", "de": "Text löschen", "pt-BR": "Limpar texto", "ar": "مسح النص", "ru": "Очистить текст",
    },
    "fkuikit.textfield.show_password": {
        "en": "Show password", "zh-Hans": "显示密码", "zh-Hant": "顯示密碼", "ja": "パスワードを表示", "ko": "비밀번호 표시",
        "es": "Mostrar contraseña", "fr": "Afficher le mot de passe", "de": "Passwort anzeigen", "pt-BR": "Mostrar senha", "ar": "إظهار كلمة المرور", "ru": "Показать пароль",
    },
    "fkuikit.textfield.hide_password": {
        "en": "Hide password", "zh-Hans": "隐藏密码", "zh-Hant": "隱藏密碼", "ja": "パスワードを非表示", "ko": "비밀번호 숨기기",
        "es": "Ocultar contraseña", "fr": "Masquer le mot de passe", "de": "Passwort verbergen", "pt-BR": "Ocultar senha", "ar": "إخفاء كلمة المرور", "ru": "Скрыть пароль",
    },
    "fkuikit.textfield.toggle_password": {
        "en": "Toggle password visibility", "zh-Hans": "切换密码可见性", "zh-Hant": "切換密碼可見性", "ja": "パスワード表示を切り替え", "ko": "비밀번호 표시 전환",
        "es": "Alternar visibilidad de contraseña", "fr": "Basculer la visibilité du mot de passe", "de": "Passwortsichtbarkeit umschalten", "pt-BR": "Alternar visibilidade da senha", "ar": "تبديل إظهار كلمة المرور", "ru": "Переключить видимость пароля",
    },
    "fkuikit.textfield.counter_prefix": {
        "en": "Character count", "zh-Hans": "字符数", "zh-Hant": "字元數", "ja": "文字数", "ko": "글자 수",
        "es": "Recuento de caracteres", "fr": "Nombre de caractères", "de": "Zeichenanzahl", "pt-BR": "Contagem de caracteres", "ar": "عدد الأحرف", "ru": "Количество символов",
    },
    "fkuikit.textfield.error_prefix": {
        "en": "Error", "zh-Hans": "错误", "zh-Hant": "錯誤", "ja": "エラー", "ko": "오류",
        "es": "Error", "fr": "Erreur", "de": "Fehler", "pt-BR": "Erro", "ar": "خطأ", "ru": "Ошибка",
    },
    "fkuikit.textfield.success_prefix": {
        "en": "Success", "zh-Hans": "成功", "zh-Hant": "成功", "ja": "成功", "ko": "성공",
        "es": "Éxito", "fr": "Succès", "de": "Erfolg", "pt-BR": "Sucesso", "ar": "نجاح", "ru": "Успех",
    },
    "fkuikit.textfield.placeholder.email": {
        "en": "Email", "zh-Hans": "邮箱", "zh-Hant": "電子郵件", "ja": "メール", "ko": "이메일",
        "es": "Correo electrónico", "fr": "E-mail", "de": "E-Mail", "pt-BR": "E-mail", "ar": "البريد الإلكتروني", "ru": "Эл. почта",
    },
    "fkuikit.textfield.placeholder.password": {
        "en": "Password", "zh-Hans": "密码", "zh-Hant": "密碼", "ja": "パスワード", "ko": "비밀번호",
        "es": "Contraseña", "fr": "Mot de passe", "de": "Passwort", "pt-BR": "Senha", "ar": "كلمة المرور", "ru": "Пароль",
    },
    "fkuikit.textfield.placeholder.phone": {
        "en": "Phone number", "zh-Hans": "手机号", "zh-Hant": "手機號碼", "ja": "電話番号", "ko": "전화번호",
        "es": "Número de teléfono", "fr": "Numéro de téléphone", "de": "Telefonnummer", "pt-BR": "Número de telefone", "ar": "رقم الهاتف", "ru": "Номер телефона",
    },
    "fkuikit.textfield.validation.required": {
        "en": "This field is required.", "zh-Hans": "此字段为必填项。", "zh-Hant": "此欄位為必填。", "ja": "この項目は必須です。", "ko": "필수 입력 항목입니다.",
        "es": "Este campo es obligatorio.", "fr": "Ce champ est obligatoire.", "de": "Dieses Feld ist erforderlich.", "pt-BR": "Este campo é obrigatório.", "ar": "هذا الحقل مطلوب.", "ru": "Это поле обязательно.",
    },
    "fkuikit.textfield.validation.too_short": {
        "en": "Input is too short.", "zh-Hans": "输入过短。", "zh-Hant": "輸入過短。", "ja": "入力が短すぎます。", "ko": "입력이 너무 짧습니다.",
        "es": "La entrada es demasiado corta.", "fr": "La saisie est trop courte.", "de": "Eingabe ist zu kurz.", "pt-BR": "Entrada muito curta.", "ar": "الإدخال قصير جدًا.", "ru": "Ввод слишком короткий.",
    },
    "fkuikit.textfield.validation.too_long": {
        "en": "Input exceeds max length.", "zh-Hans": "输入超出最大长度。", "zh-Hant": "輸入超出最大長度。", "ja": "入力が最大長を超えています。", "ko": "입력이 최대 길이를 초과했습니다.",
        "es": "La entrada supera la longitud máxima.", "fr": "La saisie dépasse la longueur maximale.", "de": "Eingabe überschreitet die maximale Länge.", "pt-BR": "Entrada excede o comprimento máximo.", "ar": "الإدخال يتجاوز الحد الأقصى.", "ru": "Ввод превышает максимальную длину.",
    },
    "fkuikit.textfield.validation.email": {
        "en": "Invalid email address.", "zh-Hans": "邮箱地址无效。", "zh-Hant": "電子郵件地址無效。", "ja": "メールアドレスが無効です。", "ko": "잘못된 이메일 주소입니다.",
        "es": "Dirección de correo no válida.", "fr": "Adresse e-mail non valide.", "de": "Ungültige E-Mail-Adresse.", "pt-BR": "Endereço de e-mail inválido.", "ar": "عنوان بريد إلكتروني غير صالح.", "ru": "Недопустимый адрес эл. почты.",
    },
    "fkuikit.video.play": {
        "en": "Play", "zh-Hans": "播放", "zh-Hant": "播放", "ja": "再生", "ko": "재생",
        "es": "Reproducir", "fr": "Lecture", "de": "Wiedergabe", "pt-BR": "Reproduzir", "ar": "تشغيل", "ru": "Воспроизвести",
    },
    "fkuikit.video.pause": {
        "en": "Pause", "zh-Hans": "暂停", "zh-Hant": "暫停", "ja": "一時停止", "ko": "일시정지",
        "es": "Pausar", "fr": "Pause", "de": "Pause", "pt-BR": "Pausar", "ar": "إيقاف مؤقت", "ru": "Пауза",
    },
    "fkuikit.video.loading": FKCORE["fkcore.common.loading"],
    "fkuikit.video.retry": FKCORE["fkcore.common.retry"],
    "fkuikit.video.fullscreen": {
        "en": "Full screen", "zh-Hans": "全屏", "zh-Hant": "全螢幕", "ja": "全画面", "ko": "전체 화면",
        "es": "Pantalla completa", "fr": "Plein écran", "de": "Vollbild", "pt-BR": "Tela cheia", "ar": "ملء الشاشة", "ru": "Полный экран",
    },
    "fkuikit.video.settings": {
        "en": "Playback settings", "zh-Hans": "播放设置", "zh-Hant": "播放設定", "ja": "再生設定", "ko": "재생 설정",
        "es": "Ajustes de reproducción", "fr": "Paramètres de lecture", "de": "Wiedergabeeinstellungen", "pt-BR": "Configurações de reprodução", "ar": "إعدادات التشغيل", "ru": "Настройки воспроизведения",
    },
    "fkuikit.video.live": {
        "en": "Live", "zh-Hans": "直播", "zh-Hant": "直播", "ja": "ライブ", "ko": "라이브",
        "es": "En vivo", "fr": "Direct", "de": "Live", "pt-BR": "Ao vivo", "ar": "مباشر", "ru": "Эфир",
    },
    "fkuikit.video.close": FKCORE["fkcore.common.dismiss"],
    "fkuikit.video.progress": {
        "en": "Playback progress", "zh-Hans": "播放进度", "zh-Hant": "播放進度", "ja": "再生進捗", "ko": "재생 진행",
        "es": "Progreso de reproducción", "fr": "Progression de lecture", "de": "Wiedergabefortschritt", "pt-BR": "Progresso da reprodução", "ar": "تقدم التشغيل", "ru": "Прогресс воспроизведения",
    },
    "fkuikit.video.screen_capture": {
        "en": "Screen recording is not allowed", "zh-Hans": "不允许录屏", "zh-Hant": "不允許錄屏", "ja": "画面録画は許可されていません", "ko": "화면 녹화가 허용되지 않습니다",
        "es": "No se permite la grabación de pantalla", "fr": "L'enregistrement d'écran n'est pas autorisé", "de": "Bildschirmaufnahme ist nicht erlaubt", "pt-BR": "Gravação de tela não permitida", "ar": "تسجيل الشاشة غير مسموح", "ru": "Запись экрана запрещена",
    },
    "fkuikit.audio.play": {
        "en": "Play", "zh-Hans": "播放", "zh-Hant": "播放", "ja": "再生", "ko": "재생",
        "es": "Reproducir", "fr": "Lecture", "de": "Wiedergabe", "pt-BR": "Reproduzir", "ar": "تشغيل", "ru": "Воспроизвести",
    },
    "fkuikit.audio.pause": {
        "en": "Pause", "zh-Hans": "暂停", "zh-Hant": "暫停", "ja": "一時停止", "ko": "일시정지",
        "es": "Pausar", "fr": "Pause", "de": "Pause", "pt-BR": "Pausar", "ar": "إيقاف مؤقت", "ru": "Пауза",
    },
    "fkuikit.audio.next": {
        "en": "Next track", "zh-Hans": "下一曲", "zh-Hant": "下一曲", "ja": "次の曲", "ko": "다음 트랙",
        "es": "Siguiente pista", "fr": "Piste suivante", "de": "Nächster Titel", "pt-BR": "Próxima faixa", "ar": "المقطع التالي", "ru": "Следующий трек",
    },
    "fkuikit.audio.previous": {
        "en": "Previous track", "zh-Hans": "上一曲", "zh-Hant": "上一曲", "ja": "前の曲", "ko": "이전 트랙",
        "es": "Pista anterior", "fr": "Piste précédente", "de": "Vorheriger Titel", "pt-BR": "Faixa anterior", "ar": "المقطع السابق", "ru": "Предыдущий трек",
    },
    "fkuikit.audio.retry": FKCORE["fkcore.common.retry"],
    "fkuikit.audio.sleep": {
        "en": "Sleep timer", "zh-Hans": "睡眠定时", "zh-Hant": "睡眠定時", "ja": "スリープタイマー", "ko": "수면 타이머",
        "es": "Temporizador de sueño", "fr": "Minuterie de veille", "de": "Schlaf-Timer", "pt-BR": "Timer de sono", "ar": "مؤقت النوم", "ru": "Таймер сна",
    },
    "fkuikit.audio.rate": {
        "en": "Playback speed", "zh-Hans": "播放速度", "zh-Hant": "播放速度", "ja": "再生速度", "ko": "재생 속도",
        "es": "Velocidad de reproducción", "fr": "Vitesse de lecture", "de": "Wiedergabegeschwindigkeit", "pt-BR": "Velocidade de reprodução", "ar": "سرعة التشغيل", "ru": "Скорость воспроизведения",
    },
    "fkuikit.audio.close": FKCORE["fkcore.common.dismiss"],
    "fkuikit.empty.action.retry": FKCORE["fkcore.common.retry"],
    "fkuikit.empty.empty.title": {
        "en": "Nothing here yet", "zh-Hans": "暂无内容", "zh-Hant": "暫無內容", "ja": "まだ何もありません", "ko": "아직 내용이 없습니다",
        "es": "Aún no hay nada", "fr": "Rien ici pour l'instant", "de": "Noch nichts hier", "pt-BR": "Nada aqui ainda", "ar": "لا يوجد شيء هنا بعد", "ru": "Пока ничего нет",
    },
    "fkuikit.empty.empty.description": {
        "en": "There is no data to display.", "zh-Hans": "没有可显示的数据。", "zh-Hant": "沒有可顯示的資料。", "ja": "表示するデータがありません。", "ko": "표시할 데이터가 없습니다.",
        "es": "No hay datos para mostrar.", "fr": "Aucune donnée à afficher.", "de": "Keine Daten zum Anzeigen.", "pt-BR": "Não há dados para exibir.", "ar": "لا توجد بيانات للعرض.", "ru": "Нет данных для отображения.",
    },
    "fkuikit.empty.noResults.title": {
        "en": "No results", "zh-Hans": "未找到结果", "zh-Hant": "未找到結果", "ja": "結果がありません", "ko": "결과 없음",
        "es": "Sin resultados", "fr": "Aucun résultat", "de": "Keine Ergebnisse", "pt-BR": "Sem resultados", "ar": "لا توجد نتائج", "ru": "Нет результатов",
    },
    "fkuikit.empty.noResults.description": {
        "en": "No matches for \"{query}\". Try a different keyword.",
        "zh-Hans": "没有与「{query}」匹配的结果，请尝试其他关键词。", "zh-Hant": "沒有與「{query}」匹配的結果，請嘗試其他關鍵詞。", "ja": "「{query}」に一致する結果がありません。別のキーワードをお試しください。",
        "ko": "\"{query}\"에 대한 결과가 없습니다. 다른 키워드를 시도하세요.", "es": "Sin coincidencias para \"{query}\". Prueba otra palabra clave.",
        "fr": "Aucun résultat pour « {query} ». Essayez un autre mot-clé.", "de": "Keine Treffer für „{query}“. Versuchen Sie ein anderes Stichwort.",
        "pt-BR": "Nenhuma correspondência para \"{query}\". Tente outra palavra-chave.", "ar": "لا توجد نتائج لـ \"{query}\". جرّب كلمة مختلفة.", "ru": "Нет совпадений для «{query}». Попробуйте другое слово.",
    },
    "fkuikit.empty.error.title": FKCORE["fkcore.common.error"],
    "fkuikit.empty.error.description": {
        "en": "We couldn't load the content. Please try again.", "zh-Hans": "无法加载内容，请重试。", "zh-Hant": "無法載入內容，請重試。", "ja": "コンテンツを読み込めませんでした。もう一度お試しください。", "ko": "콘텐츠를 불러올 수 없습니다. 다시 시도하세요.",
        "es": "No pudimos cargar el contenido. Inténtalo de nuevo.", "fr": "Impossible de charger le contenu. Veuillez réessayer.", "de": "Inhalt konnte nicht geladen werden. Bitte erneut versuchen.", "pt-BR": "Não foi possível carregar o conteúdo. Tente novamente.", "ar": "تعذر تحميل المحتوى. يرجى المحاولة مرة أخرى.", "ru": "Не удалось загрузить содержимое. Попробуйте снова.",
    },
    "fkuikit.empty.offline.title": FKCORE["fkcore.network.offline"],
    "fkuikit.empty.offline.description": {
        "en": "Check your connection and try again.", "zh-Hans": "请检查网络连接后重试。", "zh-Hant": "請檢查網路連線後重試。", "ja": "接続を確認してもう一度お試しください。", "ko": "연결을 확인하고 다시 시도하세요.",
        "es": "Comprueba tu conexión e inténtalo de nuevo.", "fr": "Vérifiez votre connexion et réessayez.", "de": "Überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.", "pt-BR": "Verifique sua conexão e tente novamente.", "ar": "تحقق من اتصالك وحاول مرة أخرى.", "ru": "Проверьте подключение и попробуйте снова.",
    },
    "fkuikit.empty.action.refresh": {
        "en": "Refresh", "zh-Hans": "刷新", "zh-Hant": "重新整理", "ja": "更新", "ko": "새로고침",
        "es": "Actualizar", "fr": "Actualiser", "de": "Aktualisieren", "pt-BR": "Atualizar", "ar": "تحديث", "ru": "Обновить",
    },
}
# fmt: on

FKCORE.update(FKCORE_EXT)
FKUI.update(FKUI_EXT)


def escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def write_strings(base: Path, module: str, table: dict[str, dict[str, str]]) -> None:
    for lang in LANGS:
        out = base / "Localization" / f"{lang}.lproj" / "Localizable.strings"
        out.parent.mkdir(parents=True, exist_ok=True)
        lines = [f"/* {module} localization — {lang} */", ""]
        for key in sorted(table.keys()):
            value = table[key].get(lang, table[key]["en"])
            lines.append(f'"{key}" = "{escape(value)}";')
        lines.append("")
        out.write_text("\n".join(lines), encoding="utf-8")
        print(f"Wrote {out.relative_to(ROOT)}")


def main() -> None:
    write_strings(ROOT / "Sources/FKCoreKit/Resources", "FKCoreKit", FKCORE)
    write_strings(ROOT / "Sources/FKUIKit/Resources", "FKUIKit", FKUI)


if __name__ == "__main__":
    main()
