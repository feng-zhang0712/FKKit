"""Additional i18n keys for P0/P1/P2 coverage. Merged by generate-library-i18n.py."""

# fmt: off

def _e(en, zh_hans, zh_hant, ja, ko, es, fr, de, pt_br, ar, ru):
    return {
        "en": en, "zh-Hans": zh_hans, "zh-Hant": zh_hant, "ja": ja, "ko": ko,
        "es": es, "fr": fr, "de": de, "pt-BR": pt_br, "ar": ar, "ru": ru,
    }

FKCORE_EXT = {
    "fkcore.file.error.file_not_found": _e(
        "File not found at path: %@", "未找到文件：%@", "未找到檔案：%@", "パス %@ にファイルが見つかりません", "경로에서 파일을 찾을 수 없음: %@",
        "Archivo no encontrado en: %@", "Fichier introuvable : %@", "Datei nicht gefunden: %@", "Arquivo não encontrado em: %@", "الملف غير موجود في: %@", "Файл не найден: %@"),
    "fkcore.file.error.file_already_exists": _e(
        "File already exists at path: %@", "文件已存在：%@", "檔案已存在：%@", "パス %@ にファイルが既に存在します", "경로에 파일이 이미 존재함: %@",
        "El archivo ya existe en: %@", "Le fichier existe déjà : %@", "Datei existiert bereits: %@", "Arquivo já existe em: %@", "الملف موجود بالفعل في: %@", "Файл уже существует: %@"),
    "fkcore.file.error.invalid_url": _e(
        "Invalid URL: %@", "无效的 URL：%@", "無效的 URL：%@", "無効な URL：%@", "잘못된 URL: %@",
        "URL no válida: %@", "URL non valide : %@", "Ungültige URL: %@", "URL inválida: %@", "عنوان URL غير صالح: %@", "Недопустимый URL: %@"),
    "fkcore.file.error.transfer_failed": _e(
        "Transfer failed: %@", "传输失败：%@", "傳輸失敗：%@", "転送に失敗しました：%@", "전송 실패: %@",
        "Error de transferencia: %@", "Échec du transfert : %@", "Übertragung fehlgeschlagen: %@", "Falha na transferência: %@", "فشل النقل: %@", "Ошибка передачи: %@"),
    "fkcore.file.error.invalid_response": _e(
        "Invalid transfer response.", "无效的传输响应。", "無效的傳輸回應。", "無効な転送応答です。", "잘못된 전송 응답입니다.",
        "Respuesta de transferencia no válida.", "Réponse de transfert non valide.", "Ungültige Übertragungsantwort.", "Resposta de transferência inválida.", "استجابة نقل غير صالحة.", "Недопустимый ответ передачи."),
    "fkcore.file.error.insufficient_disk_space": _e(
        "Insufficient disk space. Required: %lld, available: %lld.", "磁盘空间不足。需要：%lld，可用：%lld。", "磁碟空間不足。需要：%lld，可用：%lld。", "ディスク容量が不足しています。必要：%lld、利用可能：%lld。", "디스크 공간 부족. 필요: %lld, 사용 가능: %lld.",
        "Espacio insuficiente. Requerido: %lld, disponible: %lld.", "Espace disque insuffisant. Requis : %lld, disponible : %lld.", "Unzureichender Speicher. Erforderlich: %lld, verfügbar: %lld.", "Espaço insuficiente. Necessário: %lld, disponível: %lld.", "مساحة قرص غير كافية. مطلوب: %lld، متاح: %lld.", "Недостаточно места. Требуется: %lld, доступно: %lld."),
    "fkcore.file.error.zip_unavailable": _e(
        "ZIP operations are unavailable on this OS version.", "此系统版本不支持 ZIP 操作。", "此系統版本不支援 ZIP 操作。", "この OS バージョンでは ZIP 操作は利用できません。", "이 OS 버전에서는 ZIP 작업을 사용할 수 없습니다.",
        "Las operaciones ZIP no están disponibles en esta versión del SO.", "Les opérations ZIP ne sont pas disponibles sur cette version.", "ZIP-Operationen sind auf dieser OS-Version nicht verfügbar.", "Operações ZIP indisponíveis nesta versão do SO.", "عمليات ZIP غير متاحة على هذا الإصدار.", "ZIP недоступен в этой версии ОС."),
    "fkcore.file.error.unknown": _e(
        "Unknown error: %@", "未知错误：%@", "未知錯誤：%@", "不明なエラー：%@", "알 수 없는 오류: %@",
        "Error desconocido: %@", "Erreur inconnue : %@", "Unbekannter Fehler: %@", "Erro desconhecido: %@", "خطأ غير معروف: %@", "Неизвестная ошибка: %@"),
    "fkcore.security.error.invalid_input": _e(
        "Invalid input: %@", "无效输入：%@", "無效輸入：%@", "無効な入力：%@", "잘못된 입력: %@",
        "Entrada no válida: %@", "Entrée non valide : %@", "Ungültige Eingabe: %@", "Entrada inválida: %@", "إدخال غير صالح: %@", "Недопустимый ввод: %@"),
    "fkcore.security.error.invalid_key": _e(
        "Invalid key material: %@", "无效的密钥材料：%@", "無效的密鑰材料：%@", "無効な鍵素材：%@", "잘못된 키 자료: %@",
        "Material de clave no válido: %@", "Matériel de clé non valide : %@", "Ungültiges Schlüsselmaterial: %@", "Material de chave inválido: %@", "مادة مفتاح غير صالحة: %@", "Недопустимый ключ: %@"),
    "fkcore.security.error.crypto_failed": _e(
        "Crypto operation failed (%d): %@", "加密操作失败（%d）：%@", "加密操作失敗（%d）：%@", "暗号操作に失敗しました（%d）：%@", "암호화 작업 실패 (%d): %@",
        "Error criptográfico (%d): %@", "Échec crypto (%d) : %@", "Krypto fehlgeschlagen (%d): %@", "Falha criptográfica (%d): %@", "فشلت عملية التشفير (%d): %@", "Ошибка шифрования (%d): %@"),
    "fkcore.security.error.security_failed": _e(
        "Security operation failed (%d): %@", "安全操作失败（%d）：%@", "安全操作失敗（%d）：%@", "セキュリティ操作に失敗しました（%d）：%@", "보안 작업 실패 (%d): %@",
        "Error de seguridad (%d): %@", "Échec sécurité (%d) : %@", "Sicherheit fehlgeschlagen (%d): %@", "Falha de segurança (%d): %@", "فشلت عملية الأمان (%d): %@", "Ошибка безопасности (%d): %@"),
    "fkcore.security.error.key_not_found": _e(
        "Key not found: %@", "未找到密钥：%@", "未找到密鑰：%@", "鍵が見つかりません：%@", "키를 찾을 수 없음: %@",
        "Clave no encontrada: %@", "Clé introuvable : %@", "Schlüssel nicht gefunden: %@", "Chave não encontrada: %@", "المفتاح غير موجود: %@", "Ключ не найден: %@"),
    "fkcore.security.error.file_failed": _e(
        "File operation failed: %@", "文件操作失败：%@", "檔案操作失敗：%@", "ファイル操作に失敗しました：%@", "파일 작업 실패: %@",
        "Error de archivo: %@", "Échec fichier : %@", "Dateioperation fehlgeschlagen: %@", "Falha na operação de arquivo: %@", "فشلت عملية الملف: %@", "Ошибка файла: %@"),
    "fkcore.security.error.unavailable": _e(
        "Unavailable: %@", "不可用：%@", "不可用：%@", "利用不可：%@", "사용 불가: %@",
        "No disponible: %@", "Indisponible : %@", "Nicht verfügbar: %@", "Indisponível: %@", "غير متاح: %@", "Недоступно: %@"),
    "fkcore.security.error.unknown": _e(
        "Unknown error: %@", "未知错误：%@", "未知錯誤：%@", "不明なエラー：%@", "알 수 없는 오류: %@",
        "Error desconocido: %@", "Erreur inconnue : %@", "Unbekannter Fehler: %@", "Erro desconhecido: %@", "خطأ غير معروف: %@", "Неизвестная ошибка: %@"),
    "fkcore.business.error.invalid_argument": _e(
        "Invalid argument: %@", "无效参数：%@", "無效參數：%@", "無効な引数：%@", "잘못된 인수: %@",
        "Argumento no válido: %@", "Argument non valide : %@", "Ungültiges Argument: %@", "Argumento inválido: %@", "وسيطة غير صالحة: %@", "Недопустимый аргумент: %@"),
    "fkcore.business.error.missing_configuration": _e(
        "Missing configuration: %@", "缺少配置：%@", "缺少設定：%@", "設定がありません：%@", "구성 누락: %@",
        "Configuración faltante: %@", "Configuration manquante : %@", "Fehlende Konfiguration: %@", "Configuração ausente: %@", "التكوين مفقود: %@", "Отсутствует конфигурация: %@"),
    "fkcore.business.error.unsupported": _e(
        "Unsupported: %@", "不支持：%@", "不支援：%@", "サポートされていません：%@", "지원되지 않음: %@",
        "No compatible: %@", "Non pris en charge : %@", "Nicht unterstützt: %@", "Não suportado: %@", "غير مدعوم: %@", "Не поддерживается: %@"),
    "fkcore.business.error.network_failed": _e(
        "Network failed: %@", "网络失败：%@", "網路失敗：%@", "ネットワークに失敗しました：%@", "네트워크 실패: %@",
        "Error de red: %@", "Échec réseau : %@", "Netzwerk fehlgeschlagen: %@", "Falha de rede: %@", "فشل الشبكة: %@", "Ошибка сети: %@"),
    "fkcore.business.error.persistence_failed": _e(
        "Persistence failed: %@", "持久化失败：%@", "持久化失敗：%@", "永続化に失敗しました：%@", "저장 실패: %@",
        "Error de persistencia: %@", "Échec persistance : %@", "Speichern fehlgeschlagen: %@", "Falha na persistência: %@", "فشل الحفظ: %@", "Ошибка сохранения: %@"),
    "fkcore.business.error.cancelled": _e(
        "Cancelled", "已取消", "已取消", "キャンセルされました", "취소됨",
        "Cancelado", "Annulé", "Abgebrochen", "Cancelado", "تم الإلغاء", "Отменено"),
    "fkcore.business.error.unknown": _e(
        "Unknown: %@", "未知：%@", "未知：%@", "不明：%@", "알 수 없음: %@",
        "Desconocido: %@", "Inconnu : %@", "Unbekannt: %@", "Desconhecido: %@", "غير معروف: %@", "Неизвестно: %@"),
    "fkcore.utils.battery.state.unknown": _e("unknown", "未知", "未知", "不明", "알 수 없음", "desconocido", "inconnu", "unbekannt", "desconhecido", "غير معروف", "неизвестно"),
    "fkcore.utils.battery.state.unplugged": _e("unplugged", "未充电", "未充電", "未接続", "연결 안 됨", "desconectado", "débranché", "nicht angeschlossen", "desconectado", "غير موصول", "не подключено"),
    "fkcore.utils.battery.state.charging": _e("charging", "充电中", "充電中", "充電中", "충전 중", "cargando", "en charge", "wird geladen", "carregando", "يشحن", "зарядка"),
    "fkcore.utils.battery.state.full": _e("full", "已充满", "已充滿", "満充電", "충전 완료", "completo", "plein", "voll", "completo", "ممتلئ", "полный"),
    "fkcore.utils.network.unreachable": _e("unreachable", "不可达", "不可達", "到達不可", "연결 불가", "inaccesible", "inaccessible", "nicht erreichbar", "inacessível", "غير متاح", "недоступно"),
    "fkcore.utils.network.wifi": _e("wifi", "Wi-Fi", "Wi-Fi", "Wi-Fi", "Wi-Fi", "wifi", "wifi", "wlan", "wifi", "واي فاي", "Wi‑Fi"),
    "fkcore.utils.network.cellular": _e("cellular", "蜂窝网络", "行動網路", "モバイル", "셀룰러", "celular", "cellulaire", "mobilfunk", "celular", "خلوي", "сотовая"),
    "fkcore.utils.network.ethernet": _e("ethernet", "以太网", "乙太網路", "Ethernet", "이더넷", "ethernet", "ethernet", "ethernet", "ethernet", "إيثرنت", "Ethernet"),
    "fkcore.utils.network.other": _e("other", "其他", "其他", "その他", "기타", "otro", "autre", "andere", "outro", "أخرى", "другое"),
    "fkcore.file.error.cannot_infer_filename": _e(
        "Cannot infer destination file name.", "无法推断目标文件名。", "無法推斷目標檔名。", "保存先ファイル名を推測できません。", "대상 파일 이름을 추론할 수 없습니다.",
        "No se puede inferir el nombre del archivo.", "Impossible de déduire le nom du fichier.", "Dateiname kann nicht abgeleitet werden.", "Não foi possível inferir o nome do arquivo.", "تعذر استنتاج اسم الملف.", "Не удалось определить имя файла."),
    "fkcore.file.error.text_encoding_failed": _e(
        "Text encoding failed.", "文本编码失败。", "文字編碼失敗。", "テキストのエンコードに失敗しました。", "텍스트 인코딩 실패.",
        "Error de codificación de texto.", "Échec de l'encodage du texte.", "Textkodierung fehlgeschlagen.", "Falha na codificação de texto.", "فشل ترميز النص.", "Ошибка кодирования текста."),
    "fkcore.file.error.text_decoding_failed": _e(
        "Text decoding failed.", "文本解码失败。", "文字解碼失敗。", "テキストのデコードに失敗しました。", "텍스트 디코딩 실패.",
        "Error de decodificación de texto.", "Échec du décodage du texte.", "Textdekodierung fehlgeschlagen.", "Falha na decodificação de texto.", "فشل فك ترميز النص.", "Ошибка декодирования текста."),
    "fkcore.security.detail.invalid_base64": _e(
        "Invalid Base64 string.", "无效的 Base64 字符串。", "無效的 Base64 字串。", "無効な Base64 文字列です。", "잘못된 Base64 문자열입니다.",
        "Cadena Base64 no válida.", "Chaîne Base64 non valide.", "Ungültige Base64-Zeichenkette.", "String Base64 inválida.", "سلسلة Base64 غير صالحة.", "Недопустимая строка Base64."),
    "fkcore.security.detail.utf8_encode_failed": _e(
        "String cannot be encoded as UTF-8.", "字符串无法编码为 UTF-8。", "字串無法編碼為 UTF-8。", "文字列を UTF-8 にエンコードできません。", "문자열을 UTF-8로 인코딩할 수 없습니다.",
        "No se puede codificar como UTF-8.", "Impossible d'encoder en UTF-8.", "UTF-8-Kodierung nicht möglich.", "Não foi possível codificar em UTF-8.", "تعذر الترميز UTF-8.", "Не удалось закодировать в UTF-8."),
    "fkcore.security.detail.invalid_ciphertext_base64": _e(
        "Ciphertext is not valid Base64.", "密文不是有效的 Base64。", "密文不是有效的 Base64。", "暗号文が有効な Base64 ではありません。", "암호문이 유효한 Base64가 아닙니다.",
        "El texto cifrado no es Base64 válido.", "Le texte chiffré n'est pas du Base64 valide.", "Ciphertext ist kein gültiges Base64.", "Texto cifrado não é Base64 válido.", "النص المشفر ليس Base64 صالحًا.", "Шифротекст не является Base64."),
    "fkcore.security.detail.utf8_decode_failed": _e(
        "Decrypted data is not valid UTF-8.", "解密数据不是有效的 UTF-8。", "解密資料不是有效的 UTF-8。", "復号データが有効な UTF-8 ではありません。", "복호화된 데이터가 유효한 UTF-8이 아닙니다.",
        "Los datos descifrados no son UTF-8 válido.", "Les données déchiffrées ne sont pas UTF-8 valides.", "Entschlüsselte Daten sind kein gültiges UTF-8.", "Dados descriptografados não são UTF-8 válido.", "البيانات المفكوكة ليست UTF-8 صالحة.", "Расшифрованные данные не UTF-8."),
    "fkcore.security.detail.aes_key_length": _e(
        "AES key length must be 16/24/32 bytes.", "AES 密钥长度必须为 16/24/32 字节。", "AES 密鑰長度必須為 16/24/32 位元組。", "AES 鍵長は 16/24/32 バイトである必要があります。", "AES 키 길이는 16/24/32바이트여야 합니다.",
        "La clave AES debe tener 16/24/32 bytes.", "La clé AES doit faire 16/24/32 octets.", "AES-Schlüssellänge muss 16/24/32 Bytes sein.", "Chave AES deve ter 16/24/32 bytes.", "يجب أن يكون طول مفتاح AES 16/24/32 بايت.", "Длина ключа AES должна быть 16/24/32 байт."),
    "fkcore.security.detail.aes_iv_length": _e(
        "AES-CBC requires a 16-byte IV.", "AES-CBC 需要 16 字节 IV。", "AES-CBC 需要 16 位元組 IV。", "AES-CBC には 16 バイト IV が必要です。", "AES-CBC는 16바이트 IV가 필요합니다.",
        "AES-CBC requiere un IV de 16 bytes.", "AES-CBC nécessite un IV de 16 octets.", "AES-CBC erfordert ein 16-Byte-IV.", "AES-CBC requer IV de 16 bytes.", "AES-CBC يتطلب IV بطول 16 بايت.", "AES-CBC требует IV длиной 16 байт."),
    "fkcore.security.detail.sec_random_failed": _e(
        "SecRandomCopyBytes failed.", "SecRandomCopyBytes 失败。", "SecRandomCopyBytes 失敗。", "SecRandomCopyBytes に失敗しました。", "SecRandomCopyBytes 실패.",
        "SecRandomCopyBytes falló.", "Échec de SecRandomCopyBytes.", "SecRandomCopyBytes fehlgeschlagen.", "SecRandomCopyBytes falhou.", "فشل SecRandomCopyBytes.", "SecRandomCopyBytes не удался."),
    "fkcore.security.detail.cccrypt_failed": _e(
        "CCCrypt failed.", "CCCrypt 失败。", "CCCrypt 失敗。", "CCCrypt に失敗しました。", "CCCrypt 실패.",
        "CCCrypt falló.", "Échec de CCCrypt.", "CCCrypt fehlgeschlagen.", "CCCrypt falhou.", "فشل CCCrypt.", "CCCrypt не удался."),
    "fkcore.security.detail.cannot_open_input_file": _e(
        "Cannot open input file: %@", "无法打开输入文件：%@", "無法開啟輸入檔案：%@", "入力ファイルを開けません：%@", "입력 파일을 열 수 없음: %@",
        "No se puede abrir el archivo de entrada: %@", "Impossible d'ouvrir le fichier d'entrée : %@", "Eingabedatei kann nicht geöffnet werden: %@", "Não foi possível abrir arquivo de entrada: %@", "تعذر فتح ملف الإدخال: %@", "Не удалось открыть входной файл: %@"),
    "fkcore.security.detail.cannot_open_output_file": _e(
        "Cannot open output file: %@", "无法打开输出文件：%@", "無法開啟輸出檔案：%@", "出力ファイルを開けません：%@", "출력 파일을 열 수 없음: %@",
        "No se puede abrir el archivo de salida: %@", "Impossible d'ouvrir le fichier de sortie : %@", "Ausgabedatei kann nicht geöffnet werden: %@", "Não foi possível abrir arquivo de saída: %@", "تعذر فتح ملف الإخراج: %@", "Не удалось открыть выходной файл: %@"),
    "fkcore.security.detail.cannot_open_hash_file": _e(
        "Cannot open file for hashing: %@", "无法打开文件进行哈希：%@", "無法開啟檔案進行雜湊：%@", "ハッシュ用ファイルを開けません：%@", "해시용 파일을 열 수 없음: %@",
        "No se puede abrir el archivo para hash: %@", "Impossible d'ouvrir le fichier pour hachage : %@", "Datei für Hash kann nicht geöffnet werden: %@", "Não foi possível abrir arquivo para hash: %@", "تعذر فتح الملف للتجزئة: %@", "Не удалось открыть файл для хеширования: %@"),
    "fkcore.security.detail.sec_item_add_failed": _e(
        "SecItemAdd failed.", "SecItemAdd 失败。", "SecItemAdd 失敗。", "SecItemAdd に失敗しました。", "SecItemAdd 실패.",
        "SecItemAdd falló.", "Échec de SecItemAdd.", "SecItemAdd fehlgeschlagen.", "SecItemAdd falhou.", "فشل SecItemAdd.", "SecItemAdd не удался."),
    "fkcore.security.detail.sec_item_delete_failed": _e(
        "SecItemDelete failed.", "SecItemDelete 失败。", "SecItemDelete 失敗。", "SecItemDelete に失敗しました。", "SecItemDelete 실패.",
        "SecItemDelete falló.", "Échec de SecItemDelete.", "SecItemDelete fehlgeschlagen.", "SecItemDelete falhou.", "فشل SecItemDelete.", "SecItemDelete не удался."),
    "fkcore.security.detail.rsa_encrypt_unsupported": _e(
        "RSA encryption algorithm is not supported by this key.", "此密钥不支持 RSA 加密算法。", "此密鑰不支援 RSA 加密演算法。", "この鍵は RSA 暗号化をサポートしていません。", "이 키는 RSA 암호화를 지원하지 않습니다.",
        "Este clave no admite cifrado RSA.", "Cette clé ne prend pas en charge le chiffrement RSA.", "RSA-Verschlüsselung wird nicht unterstützt.", "Esta chave não suporta criptografia RSA.", "خوارزمية RSA غير مدعومة.", "RSA-шифрование не поддерживается."),
    "fkcore.security.detail.rsa_decrypt_unsupported": _e(
        "RSA decryption algorithm is not supported by this key.", "此密钥不支持 RSA 解密算法。", "此密鑰不支援 RSA 解密演算法。", "この鍵は RSA 復号をサポートしていません。", "이 키는 RSA 복호화를 지원하지 않습니다.",
        "Este clave no admite descifrado RSA.", "Cette clé ne prend pas en charge le déchiffrement RSA.", "RSA-Entschlüsselung wird nicht unterstützt.", "Esta chave não suporta descriptografia RSA.", "فك RSA غير مدعوم.", "RSA-расшифровка не поддерживается."),
    "fkcore.security.detail.rsa_sign_unsupported": _e(
        "RSA signature algorithm is not supported by this key.", "此密钥不支持 RSA 签名算法。", "此密鑰不支援 RSA 簽名演算法。", "この鍵は RSA 署名をサポートしていません。", "이 키는 RSA 서명을 지원하지 않습니다.",
        "Este clave no admite firma RSA.", "Cette clé ne prend pas en charge la signature RSA.", "RSA-Signatur wird nicht unterstützt.", "Esta chave não suporta assinatura RSA.", "توقيع RSA غير مدعوم.", "RSA-подпись не поддерживается."),
    "fkcore.security.detail.rsa_verify_unsupported": _e(
        "RSA verification algorithm is not supported by this key.", "此密钥不支持 RSA 验证算法。", "此密鑰不支援 RSA 驗證演算法。", "この鍵は RSA 検証をサポートしていません。", "이 키는 RSA 검증을 지원하지 않습니다.",
        "Este clave no admite verificación RSA.", "Cette clé ne prend pas en charge la vérification RSA.", "RSA-Verifizierung wird nicht unterstützt.", "Esta chave não suporta verificação RSA.", "التحقق RSA غير مدعوم.", "RSA-проверка не поддерживается."),
    "fkcore.security.detail.sec_key_public_nil": _e(
        "SecKeyCopyPublicKey returned nil.", "SecKeyCopyPublicKey 返回 nil。", "SecKeyCopyPublicKey 返回 nil。", "SecKeyCopyPublicKey が nil を返しました。", "SecKeyCopyPublicKey가 nil을 반환했습니다.",
        "SecKeyCopyPublicKey devolvió nil.", "SecKeyCopyPublicKey a renvoyé nil.", "SecKeyCopyPublicKey gab nil zurück.", "SecKeyCopyPublicKey retornou nil.", "SecKeyCopyPublicKey أعاد nil.", "SecKeyCopyPublicKey вернул nil."),
    "fkcore.security.detail.sec_key_export_public_nil": _e(
        "SecKeyCopyExternalRepresentation returned nil for public key.", "公钥导出返回 nil。", "公鑰匯出返回 nil。", "公開鍵のエクスポートが nil を返しました。", "공개 키 내보내기가 nil을 반환했습니다.",
        "Exportación de clave pública devolvió nil.", "Export de clé publique renvoie nil.", "Öffentlicher Schlüssel-Export nil.", "Exportação de chave pública retornou nil.", "تصدير المفتاح العام أعاد nil.", "Экспорт открытого ключа вернул nil."),
    "fkcore.security.detail.sec_key_export_private_nil": _e(
        "SecKeyCopyExternalRepresentation returned nil for private key.", "私钥导出返回 nil。", "私鑰匯出返回 nil。", "秘密鍵のエクスポートが nil を返しました。", "개인 키 내보내기가 nil을 반환했습니다.",
        "Exportación de clave privada devolvió nil.", "Export de clé privée renvoie nil.", "Privater Schlüssel-Export nil.", "Exportação de chave privada retornou nil.", "تصدير المفتاح الخاص أعاد nil.", "Экспорт закрытого ключа вернул nil."),
    "fkcore.security.detail.rsa_key_size": _e(
        "RSA keySize must be 2048/3072/4096.", "RSA 密钥长度必须为 2048/3072/4096。", "RSA 密鑰長度必須為 2048/3072/4096。", "RSA 鍵サイズは 2048/3072/4096 である必要があります。", "RSA 키 크기는 2048/3072/4096이어야 합니다.",
        "El tamaño de clave RSA debe ser 2048/3072/4096.", "La taille de clé RSA doit être 2048/3072/4096.", "RSA-Schlüssellänge muss 2048/3072/4096 sein.", "Tamanho da chave RSA deve ser 2048/3072/4096.", "يجب أن يكون حجم مفتاح RSA 2048/3072/4096.", "Размер ключа RSA должен быть 2048/3072/4096."),
    "fkcore.security.detail.params_secret_utf8_failed": _e(
        "Parameters or secret cannot be encoded as UTF-8.", "参数或密钥无法编码为 UTF-8。", "參數或密鑰無法編碼為 UTF-8。", "パラメータまたはシークレットを UTF-8 にエンコードできません。", "매개변수 또는 시크릿을 UTF-8로 인코딩할 수 없습니다.",
        "Los parámetros o el secreto no se pueden codificar como UTF-8.", "Les paramètres ou le secret ne peuvent pas être encodés en UTF-8.", "Parameter oder Secret können nicht als UTF-8 kodiert werden.", "Parâmetros ou segredo não podem ser codificados em UTF-8.", "تعذر ترميز المعلمات أو السر كـ UTF-8.", "Параметры или секрет не могут быть закодированы в UTF-8."),
    "fkcore.security.detail.random_byte_count": _e(
        "Random byte count must be > 0.", "随机字节数必须大于 0。", "隨機位元組數必須大於 0。", "ランダムバイト数は 0 より大きい必要があります。", "랜덤 바이트 수는 0보다 커야 합니다.",
        "El número de bytes aleatorios debe ser > 0.", "Le nombre d'octets aléatoires doit être > 0.", "Zufallsbyte-Anzahl muss > 0 sein.", "Contagem de bytes aleatórios deve ser > 0.", "يجب أن يكون عدد البايتات العشوائية > 0.", "Количество случайных байт должно быть > 0."),
    "fkcore.security.detail.alphabet_empty": _e(
        "Alphabet must not be empty.", "字母表不能为空。", "字母表不能為空。", "アルファベットは空にできません。", "알파벳은 비어 있을 수 없습니다.",
        "El alfabeto no debe estar vacío.", "L'alphabet ne doit pas être vide.", "Alphabet darf nicht leer sein.", "Alfabeto não pode estar vazio.", "يجب ألا يكون الأبجد فارغًا.", "Алфавит не должен быть пустым."),
    "fkcore.security.detail.executable_url_nil": _e(
        "Bundle.main.executableURL is nil.", "Bundle.main.executableURL 为 nil。", "Bundle.main.executableURL 為 nil。", "Bundle.main.executableURL が nil です。", "Bundle.main.executableURL이 nil입니다.",
        "Bundle.main.executableURL es nil.", "Bundle.main.executableURL est nil.", "Bundle.main.executableURL ist nil.", "Bundle.main.executableURL é nil.", "Bundle.main.executableURL يساوي nil.", "Bundle.main.executableURL равен nil."),
    "fkcore.security.detail.passes_must_be_positive": _e(
        "passes must be >= 1.", "passes 必须 >= 1。", "passes 必須 >= 1。", "passes は 1 以上である必要があります。", "passes는 1 이상이어야 합니다.",
        "passes debe ser >= 1.", "passes doit être >= 1.", "passes muss >= 1 sein.", "passes deve ser >= 1.", "يجب أن تكون passes >= 1.", "passes должно быть >= 1."),
    "fkcore.security.detail.hex_length_even": _e(
        "HEX string length must be even.", "HEX 字符串长度必须为偶数。", "HEX 字串長度必須為偶數。", "HEX 文字列の長さは偶数である必要があります。", "HEX 문자열 길이는 짝수여야 합니다.",
        "La longitud HEX debe ser par.", "La longueur HEX doit être paire.", "HEX-Länge muss gerade sein.", "Comprimento HEX deve ser par.", "يجب أن يكون طول HEX زوجيًا.", "Длина HEX должна быть чётной."),
    "fkcore.security.detail.hex_invalid_byte": _e(
        "Invalid HEX byte: %@", "无效的 HEX 字节：%@", "無效的 HEX 位元組：%@", "無効な HEX バイト：%@", "잘못된 HEX 바이트: %@",
        "Byte HEX no válido: %@", "Octet HEX non valide : %@", "Ungültiges HEX-Byte: %@", "Byte HEX inválido: %@", "بايت HEX غير صالح: %@", "Недопустимый HEX-байт: %@"),
    "fkcore.business.version.lookup.invalid_base_url": _e(
        "Invalid iTunes lookup base URL.", "无效的 iTunes 查询基础 URL。", "無效的 iTunes 查詢基礎 URL。", "無効な iTunes ルックアップ URL です。", "잘못된 iTunes 조회 기본 URL입니다.",
        "URL base de búsqueda iTunes no válida.", "URL de base iTunes non valide.", "Ungültige iTunes-Lookup-Basis-URL.", "URL base de consulta iTunes inválida.", "عنوان URL أساسي غير صالح.", "Недопустимый базовый URL iTunes."),
    "fkcore.business.version.lookup.build_url_failed": _e(
        "Failed to build lookup URL.", "构建查询 URL 失败。", "建構查詢 URL 失敗。", "ルックアップ URL の構築に失敗しました。", "조회 URL 구성 실패.",
        "Error al crear la URL de búsqueda.", "Échec de construction de l'URL.", "Lookup-URL konnte nicht erstellt werden.", "Falha ao criar URL de consulta.", "فشل إنشاء URL.", "Не удалось построить URL."),
    "fkcore.business.version.lookup.non_200_response": _e(
        "Non-200 response.", "非 200 响应。", "非 200 回應。", "200 以外の応答です。", "200이 아닌 응답.",
        "Respuesta distinta de 200.", "Réponse autre que 200.", "Antwort ungleich 200.", "Resposta diferente de 200.", "استجابة غير 200.", "Ответ не 200."),
    "fkcore.business.version.lookup.no_version_found": _e(
        "No App Store version found for bundleId.", "未找到该 bundleId 的 App Store 版本。", "未找到該 bundleId 的 App Store 版本。", "bundleId の App Store バージョンが見つかりません。", "bundleId에 대한 App Store 버전을 찾을 수 없습니다.",
        "No se encontró versión en App Store.", "Aucune version App Store trouvée.", "Keine App-Store-Version gefunden.", "Versão App Store não encontrada.", "لم يُعثر على إصدار App Store.", "Версия App Store не найдена."),
    "fkcore.business.version.requires_ios_13": _e(
        "Requires iOS 13+.", "需要 iOS 13 或更高版本。", "需要 iOS 13 或更高版本。", "iOS 13 以降が必要です。", "iOS 13 이상이 필요합니다.",
        "Requiere iOS 13 o posterior.", "Nécessite iOS 13 ou ultérieur.", "Erfordert iOS 13+.", "Requer iOS 13 ou superior.", "يتطلب iOS 13 أو أحدث.", "Требуется iOS 13+."),
    "fkcore.permission.error.pre_prompt_cancelled": _e(
        "Permission pre-prompt was cancelled.", "权限引导已取消。", "權限引導已取消。", "権限の事前案内がキャンセルされました。", "권한 사전 안내가 취소되었습니다.",
        "Se canceló el aviso previo.", "Pré-invite annulée.", "Vorab-Hinweis abgebrochen.", "Pré-aviso cancelado.", "تم إلغاء الإشعار المسبق.", "Предварительный запрос отменён."),
    "fkcore.permission.error.unavailable": _e(
        "This permission is unavailable on this device.", "此设备不支持该权限。", "此裝置不支援該權限。", "このデバイスでは利用できません。", "이 기기에서 사용할 수 없는 권한입니다.",
        "Permiso no disponible en este dispositivo.", "Permission indisponible sur cet appareil.", "Berechtigung auf diesem Gerät nicht verfügbar.", "Permissão indisponível neste dispositivo.", "الإذن غير متاح على هذا الجهاز.", "Разрешение недоступно на этом устройстве."),
    "fkcore.security.detail.sec_key_create_random_failed": _e(
        "SecKeyCreateRandomKey failed.", "SecKeyCreateRandomKey 失败。", "SecKeyCreateRandomKey 失敗。", "SecKeyCreateRandomKey に失敗しました。", "SecKeyCreateRandomKey 실패.",
        "SecKeyCreateRandomKey falló.", "Échec de SecKeyCreateRandomKey.", "SecKeyCreateRandomKey fehlgeschlagen.", "SecKeyCreateRandomKey falhou.", "فشل SecKeyCreateRandomKey.", "SecKeyCreateRandomKey не удался."),
    "fkcore.security.detail.sec_key_encrypt_failed": _e(
        "SecKeyCreateEncryptedData failed.", "SecKeyCreateEncryptedData 失败。", "SecKeyCreateEncryptedData 失敗。", "SecKeyCreateEncryptedData に失敗しました。", "SecKeyCreateEncryptedData 실패.",
        "SecKeyCreateEncryptedData falló.", "Échec de SecKeyCreateEncryptedData.", "SecKeyCreateEncryptedData fehlgeschlagen.", "SecKeyCreateEncryptedData falhou.", "فشل SecKeyCreateEncryptedData.", "SecKeyCreateEncryptedData не удался."),
    "fkcore.security.detail.sec_key_decrypt_failed": _e(
        "SecKeyCreateDecryptedData failed.", "SecKeyCreateDecryptedData 失败。", "SecKeyCreateDecryptedData 失敗。", "SecKeyCreateDecryptedData に失敗しました。", "SecKeyCreateDecryptedData 실패.",
        "SecKeyCreateDecryptedData falló.", "Échec de SecKeyCreateDecryptedData.", "SecKeyCreateDecryptedData fehlgeschlagen.", "SecKeyCreateDecryptedData falhou.", "فشل SecKeyCreateDecryptedData.", "SecKeyCreateDecryptedData не удался."),
    "fkcore.security.detail.sec_key_sign_failed": _e(
        "SecKeyCreateSignature failed.", "SecKeyCreateSignature 失败。", "SecKeyCreateSignature 失敗。", "SecKeyCreateSignature に失敗しました。", "SecKeyCreateSignature 실패.",
        "SecKeyCreateSignature falló.", "Échec de SecKeyCreateSignature.", "SecKeyCreateSignature fehlgeschlagen.", "SecKeyCreateSignature falhou.", "فشل SecKeyCreateSignature.", "SecKeyCreateSignature не удался."),
    "fkcore.security.detail.sec_key_create_public_failed": _e(
        "SecKeyCreateWithData failed (public).", "SecKeyCreateWithData 失败（公钥）。", "SecKeyCreateWithData 失敗（公鑰）。", "SecKeyCreateWithData に失敗しました（公開鍵）。", "SecKeyCreateWithData 실패(공개).",
        "SecKeyCreateWithData falló (pública).", "Échec SecKeyCreateWithData (publique).", "SecKeyCreateWithData fehlgeschlagen (öffentlich).", "SecKeyCreateWithData falhou (pública).", "فشل SecKeyCreateWithData (عام).", "SecKeyCreateWithData не удался (открытый)."),
    "fkcore.security.detail.sec_key_create_private_failed": _e(
        "SecKeyCreateWithData failed (private).", "SecKeyCreateWithData 失败（私钥）。", "SecKeyCreateWithData 失敗（私鑰）。", "SecKeyCreateWithData に失敗しました（秘密鍵）。", "SecKeyCreateWithData 실패(개인).",
        "SecKeyCreateWithData falló (privada).", "Échec SecKeyCreateWithData (privée).", "SecKeyCreateWithData fehlgeschlagen (privat).", "SecKeyCreateWithData falhou (privada).", "فشل SecKeyCreateWithData (خاص).", "SecKeyCreateWithData не удался (закрытый)."),
    "fkcore.security.parse.asn1.unexpected_end": _e(
        "ASN.1: unexpected end.", "ASN.1：意外结束。", "ASN.1：意外結束。", "ASN.1：予期しない終端です。", "ASN.1: 예기치 않은 종료.",
        "ASN.1: fin inesperada.", "ASN.1 : fin inattendue.", "ASN.1: Unerwartetes Ende.", "ASN.1: fim inesperado.", "ASN.1: نهاية غير متوقعة.", "ASN.1: неожиданный конец."),
    "fkcore.security.parse.asn1.invalid_length": _e(
        "ASN.1: invalid length.", "ASN.1：无效长度。", "ASN.1：無效長度。", "ASN.1：無効な長さです。", "ASN.1: 잘못된 길이.",
        "ASN.1: longitud no válida.", "ASN.1 : longueur non valide.", "ASN.1: Ungültige Länge.", "ASN.1: comprimento inválido.", "ASN.1: طول غير صالح.", "ASN.1: недопустимая длина."),
    "fkcore.security.parse.asn1.missing_length": _e(
        "ASN.1: missing length.", "ASN.1：缺少长度。", "ASN.1：缺少長度。", "ASN.1：長さがありません。", "ASN.1: 길이 누락.",
        "ASN.1: falta longitud.", "ASN.1 : longueur manquante.", "ASN.1: Länge fehlt.", "ASN.1: comprimento ausente.", "ASN.1: طول مفقود.", "ASN.1: отсутствует длина."),
    "fkcore.security.parse.asn1.unsupported_length": _e(
        "ASN.1: unsupported length encoding.", "ASN.1：不支持的长度编码。", "ASN.1：不支援的長度編碼。", "ASN.1：サポートされていない長さエンコードです。", "ASN.1: 지원되지 않는 길이 인코딩.",
        "ASN.1: codificación de longitud no compatible.", "ASN.1 : encodage de longueur non pris en charge.", "ASN.1: Nicht unterstützte Längenkodierung.", "ASN.1: codificação de comprimento não suportada.", "ASN.1: ترميز طول غير مدعوم.", "ASN.1: неподдерживаемое кодирование длины."),
    "fkcore.security.parse.asn1.invalid_length_bytes": _e(
        "ASN.1: invalid length bytes.", "ASN.1：无效长度字节。", "ASN.1：無效長度位元組。", "ASN.1：無効な長さバイトです。", "ASN.1: 잘못된 길이 바이트.",
        "ASN.1: bytes de longitud no válidos.", "ASN.1 : octets de longueur non valides.", "ASN.1: Ungültige Längenbytes.", "ASN.1: bytes de comprimento inválidos.", "ASN.1: بايتات طول غير صالحة.", "ASN.1: недопустимые байты длины."),
    "fkcore.security.parse.asn1.invalid_oid": _e(
        "ASN.1: invalid OID.", "ASN.1：无效 OID。", "ASN.1：無效 OID。", "ASN.1：無効な OID です。", "ASN.1: 잘못된 OID.",
        "ASN.1: OID no válido.", "ASN.1 : OID non valide.", "ASN.1: Ungültige OID.", "ASN.1: OID inválido.", "ASN.1: OID غير صالح.", "ASN.1: недопустимый OID."),
    "fkcore.security.parse.pkcs8.expected_sequence": _e(
        "PKCS#8: expected SEQUENCE.", "PKCS#8：应为 SEQUENCE。", "PKCS#8：應為 SEQUENCE。", "PKCS#8：SEQUENCE が必要です。", "PKCS#8: SEQUENCE 필요.",
        "PKCS#8: se esperaba SEQUENCE.", "PKCS#8 : SEQUENCE attendu.", "PKCS#8: SEQUENCE erwartet.", "PKCS#8: SEQUENCE esperado.", "PKCS#8: SEQUENCE متوقع.", "PKCS#8: ожидался SEQUENCE."),
    "fkcore.security.parse.pkcs8.expected_octet_string": _e(
        "PKCS#8: expected OCTET STRING.", "PKCS#8：应为 OCTET STRING。", "PKCS#8：應為 OCTET STRING。", "PKCS#8：OCTET STRING が必要です。", "PKCS#8: OCTET STRING 필요.",
        "PKCS#8: se esperaba OCTET STRING.", "PKCS#8 : OCTET STRING attendu.", "PKCS#8: OCTET STRING erwartet.", "PKCS#8: OCTET STRING esperado.", "PKCS#8: OCTET STRING متوقع.", "PKCS#8: ожидался OCTET STRING."),
    "fkcore.security.parse.spki.expected_sequence": _e(
        "SPKI: expected SEQUENCE.", "SPKI：应为 SEQUENCE。", "SPKI：應為 SEQUENCE。", "SPKI：SEQUENCE が必要です。", "SPKI: SEQUENCE 필요.",
        "SPKI: se esperaba SEQUENCE.", "SPKI : SEQUENCE attendu.", "SPKI: SEQUENCE erwartet.", "SPKI: SEQUENCE esperado.", "SPKI: SEQUENCE متوقع.", "SPKI: ожидался SEQUENCE."),
    "fkcore.security.parse.spki.expected_bit_string": _e(
        "SPKI: expected BIT STRING.", "SPKI：应为 BIT STRING。", "SPKI：應為 BIT STRING。", "SPKI：BIT STRING が必要です。", "SPKI: BIT STRING 필요.",
        "SPKI: se esperaba BIT STRING.", "SPKI : BIT STRING attendu.", "SPKI: BIT STRING erwartet.", "SPKI: BIT STRING esperado.", "SPKI: BIT STRING متوقع.", "SPKI: ожидался BIT STRING."),
    "fkcore.security.parse.spki.empty_bit_string": _e(
        "SPKI: empty BIT STRING.", "SPKI：BIT STRING 为空。", "SPKI：BIT STRING 為空。", "SPKI：BIT STRING が空です。", "SPKI: BIT STRING 비어 있음.",
        "SPKI: BIT STRING vacío.", "SPKI : BIT STRING vide.", "SPKI: Leerer BIT STRING.", "SPKI: BIT STRING vazio.", "SPKI: BIT STRING فارغ.", "SPKI: пустой BIT STRING."),
    "fkcore.security.parse.rsa_public.expected_sequence": _e(
        "RSAPublicKey: expected SEQUENCE.", "RSAPublicKey：应为 SEQUENCE。", "RSAPublicKey：應為 SEQUENCE。", "RSAPublicKey：SEQUENCE が必要です。", "RSAPublicKey: SEQUENCE 필요.",
        "RSAPublicKey: se esperaba SEQUENCE.", "RSAPublicKey : SEQUENCE attendu.", "RSAPublicKey: SEQUENCE erwartet.", "RSAPublicKey: SEQUENCE esperado.", "RSAPublicKey: SEQUENCE متوقع.", "RSAPublicKey: ожидался SEQUENCE."),
    "fkcore.security.parse.rsa_public.expected_modulus": _e(
        "RSAPublicKey: expected INTEGER modulus.", "RSAPublicKey：应为 INTEGER 模数。", "RSAPublicKey：應為 INTEGER 模數。", "RSAPublicKey：INTEGER 法則が必要です。", "RSAPublicKey: INTEGER 모듈러스 필요.",
        "RSAPublicKey: se esperaba módulo INTEGER.", "RSAPublicKey : module INTEGER attendu.", "RSAPublicKey: INTEGER-Modulus erwartet.", "RSAPublicKey: módulo INTEGER esperado.", "RSAPublicKey: وحدة INTEGER متوقعة.", "RSAPublicKey: ожидался INTEGER modulus."),
    "fkcore.security.parse.rsa_private.expected_sequence": _e(
        "RSAPrivateKey: expected SEQUENCE.", "RSAPrivateKey：应为 SEQUENCE。", "RSAPrivateKey：應為 SEQUENCE。", "RSAPrivateKey：SEQUENCE が必要です。", "RSAPrivateKey: SEQUENCE 필요.",
        "RSAPrivateKey: se esperaba SEQUENCE.", "RSAPrivateKey : SEQUENCE attendu.", "RSAPrivateKey: SEQUENCE erwartet.", "RSAPrivateKey: SEQUENCE esperado.", "RSAPrivateKey: SEQUENCE متوقع.", "RSAPrivateKey: ожидался SEQUENCE."),
    "fkcore.security.parse.rsa_private.expected_modulus": _e(
        "RSAPrivateKey: expected INTEGER modulus.", "RSAPrivateKey：应为 INTEGER 模数。", "RSAPrivateKey：應為 INTEGER 模數。", "RSAPrivateKey：INTEGER 法則が必要です。", "RSAPrivateKey: INTEGER 모듈러스 필요.",
        "RSAPrivateKey: se esperaba módulo INTEGER.", "RSAPrivateKey : module INTEGER attendu.", "RSAPrivateKey: INTEGER-Modulus erwartet.", "RSAPrivateKey: módulo INTEGER esperado.", "RSAPrivateKey: وحدة INTEGER متوقعة.", "RSAPrivateKey: ожидался INTEGER modulus."),
}

FKUI_EXT = {
    "fkuikit.media.error.unsupported_format": _e("Unsupported format: %@", "不支持的格式：%@", "不支援的格式：%@", "サポートされていない形式：%@", "지원되지 않는 형식: %@",
        "Formato no compatible: %@", "Format non pris en charge : %@", "Nicht unterstütztes Format: %@", "Formato não suportado: %@", "تنسيق غير مدعوم: %@", "Неподдерживаемый формат: %@"),
    "fkuikit.media.error.transcoding_required": _e("Transcoding required. Suggested delivery: %@", "需要转码。建议传输方式：%@", "需要轉碼。建議傳輸方式：%@", "トランスコードが必要です。推奨：%@", "트랜스코딩 필요. 권장: %@",
        "Se requiere transcodificación. Entrega sugerida: %@", "Transcodage requis. Livraison suggérée : %@", "Transcodierung erforderlich. Vorschlag: %@", "Transcodificação necessária. Sugestão: %@", "يلزم التحويل. التسليم المقترح: %@", "Требуется транскодирование. Рекомендуется: %@"),
    "fkuikit.media.error.network_unavailable": _e("Network is unavailable.", "网络不可用。", "網路不可用。", "ネットワークが利用できません。", "네트워크를 사용할 수 없습니다.",
        "La red no está disponible.", "Réseau indisponible.", "Netzwerk nicht verfügbar.", "Rede indisponível.", "الشبكة غير متاحة.", "Сеть недоступна."),
    "fkuikit.media.error.http_status": _e("HTTP error %lld.", "HTTP 错误 %lld。", "HTTP 錯誤 %lld。", "HTTP エラー %lld。", "HTTP 오류 %lld.",
        "Error HTTP %lld.", "Erreur HTTP %lld.", "HTTP-Fehler %lld.", "Erro HTTP %lld.", "خطأ HTTP %lld.", "HTTP-ошибка %lld."),
    "fkuikit.media.error.drm_failed": _e("DRM failed: %@", "DRM 失败：%@", "DRM 失敗：%@", "DRM に失敗しました：%@", "DRM 실패: %@",
        "Error DRM: %@", "Échec DRM : %@", "DRM fehlgeschlagen: %@", "Falha DRM: %@", "فشل DRM: %@", "Ошибка DRM: %@"),
    "fkuikit.media.error.engine_failed": _e("Engine %@ failed: %@", "引擎 %@ 失败：%@", "引擎 %@ 失敗：%@", "エンジン %@ が失敗しました：%@", "엔진 %@ 실패: %@",
        "Motor %@ falló: %@", "Moteur %@ a échoué : %@", "Engine %@ fehlgeschlagen: %@", "Motor %@ falhou: %@", "فشل المحرك %@: %@", "Движок %@ ошибка: %@"),
    "fkuikit.media.error.seek_failed": _e("Seek operation failed.", "跳转失败。", "跳轉失敗。", "シーク操作に失敗しました。", "탐색 작업 실패.",
        "Error al buscar.", "Échec du positionnement.", "Suche fehlgeschlagen.", "Falha ao buscar.", "فشل التقديم.", "Ошибка перемотки."),
    "fkuikit.media.error.not_implemented": _e("Not implemented: %@", "未实现：%@", "未實現：%@", "未実装：%@", "구현되지 않음: %@",
        "No implementado: %@", "Non implémenté : %@", "Nicht implementiert: %@", "Não implementado: %@", "غير منفذ: %@", "Не реализовано: %@"),
    "fkuikit.media.feature.share_play": _e("SharePlay / GroupActivities", "SharePlay / GroupActivities", "SharePlay / GroupActivities", "SharePlay / GroupActivities", "SharePlay / GroupActivities",
        "SharePlay / GroupActivities", "SharePlay / GroupActivities", "SharePlay / GroupActivities", "SharePlay / GroupActivities", "SharePlay / GroupActivities", "SharePlay / GroupActivities"),
    "fkuikit.media.feature.photo_asset_resolver": _e("photoAsset resolver", "photoAsset 解析器", "photoAsset 解析器", "photoAsset リゾルバ", "photoAsset 리졸버",
        "resolvedor photoAsset", "résolveur photoAsset", "photoAsset-Resolver", "resolvedor photoAsset", "محلل photoAsset", "резолвер photoAsset"),
    "fkuikit.media.error.invalid_state": _e("Invalid state: %@", "无效状态：%@", "無效狀態：%@", "無効な状態：%@", "잘못된 상태: %@",
        "Estado no válido: %@", "État non valide : %@", "Ungültiger Zustand: %@", "Estado inválido: %@", "حالة غير صالحة: %@", "Недопустимое состояние: %@"),
    "fkuikit.media.error.playback_timeout": _e("Timed out waiting for player item", "等待播放项超时", "等待播放項目逾時", "プレイヤーアイテムの待機がタイムアウト", "플레이어 항목 대기 시간 초과",
        "Tiempo de espera agotado", "Délai d'attente dépassé", "Zeitüberschreitung beim Warten", "Tempo esgotado aguardando item", "انتهت مهلة انتظار العنصر", "Таймаут ожидания элемента"),
    "fkuikit.media.error.playback_failed": _e("Playback failed", "播放失败", "播放失敗", "再生に失敗しました", "재생 실패",
        "Error de reproducción", "Échec de lecture", "Wiedergabe fehlgeschlagen", "Falha na reprodução", "فشل التشغيل", "Ошибка воспроизведения"),
    "fkuikit.media.error.item_failed": _e("Item failed", "项目失败", "項目失敗", "アイテムに失敗しました", "항목 실패",
        "Error del elemento", "Échec de l'élément", "Element fehlgeschlagen", "Falha no item", "فشل العنصر", "Ошибка элемента"),
    "fkuikit.media.error.not_playable": _e("Asset is not playable", "资源无法播放", "資源無法播放", "アセットは再生できません", "에셋을 재생할 수 없음",
        "El recurso no es reproducible", "Ressource non lisible", "Asset nicht abspielbar", "Recurso não reproduzível", "الأصل غير قابل للتشغيل", "Ресурс не воспроизводится"),
    "fkuikit.media.error.unknown_load_status": _e("Unknown asset load status", "未知的资源加载状态", "未知的資源載入狀態", "不明なアセット読み込み状態", "알 수 없는 에셋 로드 상태",
        "Estado de carga desconocido", "État de chargement inconnu", "Unbekannter Ladestatus", "Status de carregamento desconhecido", "حالة تحميل غير معروفة", "Неизвестный статус загрузки"),
    "fkuikit.media.error.load_timeout": _e("Asset load timed out", "资源加载超时", "資源載入逾時", "アセット読み込みがタイムアウト", "에셋 로드 시간 초과",
        "Tiempo de carga agotado", "Chargement expiré", "Laden Zeitüberschreitung", "Tempo de carregamento esgotado", "انتهت مهلة التحميل", "Таймаут загрузки"),
    "fkuikit.textfield.validation.shorter_than_min": _e("Input is shorter than minimum length.", "输入短于最小长度。", "輸入短於最小長度。", "入力が最小長より短いです。", "입력이 최소 길이보다 짧습니다.",
        "La entrada es más corta que la longitud mínima.", "Saisie trop courte.", "Eingabe kürzer als Mindestlänge.", "Entrada menor que o mínimo.", "الإدخال أقصر من الحد الأدنى.", "Ввод короче минимальной длины."),
    "fkuikit.textfield.validation.phone_11_digits": _e("Phone number must be 11 digits.", "手机号必须为 11 位。", "手機號必須為 11 位。", "電話番号は11桁である必要があります。", "전화번호는 11자리여야 합니다.",
        "El teléfono debe tener 11 dígitos.", "Le numéro doit comporter 11 chiffres.", "Telefonnummer muss 11 Ziffern haben.", "Telefone deve ter 11 dígitos.", "يجب أن يكون 11 رقمًا.", "Номер должен содержать 11 цифр."),
    "fkuikit.textfield.validation.id_card": _e("Invalid ID card format.", "身份证格式无效。", "身分證格式無效。", "身分証の形式が無効です。", "신분증 형식이 잘못되었습니다.",
        "Formato de ID no válido.", "Format de carte d'identité non valide.", "Ungültiges Ausweisformat.", "Formato de ID inválido.", "تنسيق بطاقة الهوية غير صالح.", "Неверный формат ID."),
    "fkuikit.textfield.validation.bank_card": _e("Bank card length is invalid.", "银行卡长度无效。", "銀行卡長度無效。", "銀行カードの長さが無効です。", "은행 카드 길이가 잘못되었습니다.",
        "Longitud de tarjeta no válida.", "Longueur de carte bancaire non valide.", "Ungültige Kartenlänge.", "Comprimento de cartão inválido.", "طول البطاقة غير صالح.", "Неверная длина карты."),
    "fkuikit.textfield.validation.verification_code": _e("Verification code is incomplete.", "验证码不完整。", "驗證碼不完整。", "確認コードが不完全です。", "인증 코드가 불완전합니다.",
        "Código de verificación incompleto.", "Code de vérification incomplet.", "Bestätigungscode unvollständig.", "Código de verificação incompleto.", "رمز التحقق غير مكتمل.", "Код подтверждения неполный."),
    "fkuikit.textfield.validation.password_short": _e("Password is too short.", "密码过短。", "密碼過短。", "パスワードが短すぎます。", "비밀번호가 너무 짧습니다.",
        "Contraseña demasiado corta.", "Mot de passe trop court.", "Passwort zu kurz.", "Senha muito curta.", "كلمة المرور قصيرة جدًا.", "Пароль слишком короткий."),
    "fkuikit.textfield.validation.password_strength": _e("Password must include uppercase, lowercase and number.", "密码须包含大小写字母和数字。", "密碼須包含大小寫字母和數字。", "大文字・小文字・数字を含めてください。", "대소문자와 숫자를 포함해야 합니다.",
        "Debe incluir mayúsculas, minúsculas y números.", "Doit inclure majuscules, minuscules et chiffres.", "Groß-, Kleinbuchstaben und Zahl erforderlich.", "Deve incluir maiúsculas, minúsculas e números.", "يجب أن تتضمن أحرفًا كبيرة وصغيرة ورقمًا.", "Нужны заглавные, строчные буквы и цифра."),
    "fkuikit.textfield.validation.amount": _e("Invalid amount format.", "金额格式无效。", "金額格式無效。", "金額形式が無効です。", "금액 형식이 잘못되었습니다.",
        "Formato de monto no válido.", "Format de montant non valide.", "Ungültiges Betragsformat.", "Formato de valor inválido.", "تنسيق المبلغ غير صالح.", "Неверный формат суммы."),
    "fkuikit.textfield.validation.numeric_only": _e("Only numbers are allowed.", "仅允许数字。", "僅允許數字。", "数字のみ入力できます。", "숫자만 입력할 수 있습니다.",
        "Solo se permiten números.", "Seuls les chiffres sont autorisés.", "Nur Zahlen erlaubt.", "Apenas números permitidos.", "الأرقام فقط مسموحة.", "Разрешены только цифры."),
    "fkuikit.textfield.validation.letters_only": _e("Only letters are allowed.", "仅允许字母。", "僅允許字母。", "文字のみ入力できます。", "문자만 입력할 수 있습니다.",
        "Solo se permiten letras.", "Seules les lettres sont autorisées.", "Nur Buchstaben erlaubt.", "Apenas letras permitidas.", "الحروف فقط مسموحة.", "Разрешены только буквы."),
    "fkuikit.textfield.validation.alphanumeric_only": _e("Only letters and numbers are allowed.", "仅允许字母和数字。", "僅允許字母和數字。", "英数字のみ入力できます。", "문자와 숫자만 입력할 수 있습니다.",
        "Solo letras y números.", "Lettres et chiffres uniquement.", "Nur Buchstaben und Zahlen.", "Apenas letras e números.", "الحروف والأرقام فقط.", "Разрешены только буквы и цифры."),
    "fkuikit.textfield.validation.custom": _e("Invalid custom input.", "自定义输入无效。", "自訂輸入無效。", "カスタム入力が無効です。", "사용자 지정 입력이 잘못되었습니다.",
        "Entrada personalizada no válida.", "Saisie personnalisée non valide.", "Ungültige benutzerdefinierte Eingabe.", "Entrada personalizada inválida.", "إدخال مخصص غير صالح.", "Недопустимый пользовательский ввод."),
    "fkuikit.textfield.validation.invalid_format": _e("Invalid format.", "格式无效。", "格式無效。", "形式が無効です。", "형식이 잘못되었습니다.",
        "Formato no válido.", "Format non valide.", "Ungültiges Format.", "Formato inválido.", "تنسيق غير صالح.", "Неверный формат."),
    "fkuikit.video.settings.playback_title": _e("Playback", "播放", "播放", "再生", "재생", "Reproducción", "Lecture", "Wiedergabe", "Reprodução", "التشغيل", "Воспроизведение"),
    "fkuikit.video.settings.normal_speed": _e("Normal Speed", "正常速度", "正常速度", "通常速度", "보통 속도", "Velocidad normal", "Vitesse normale", "Normale Geschwindigkeit", "Velocidade normal", "السرعة العادية", "Обычная скорость"),
    "fkuikit.video.settings.lower_quality": _e("Lower Quality", "降低画质", "降低畫質", "画質を下げる", "낮은 화질", "Menor calidad", "Qualité inférieure", "Geringere Qualität", "Qualidade inferior", "جودة أقل", "Низкое качество"),
    "fkuikit.video.settings.higher_quality": _e("Higher Quality", "提高画质", "提高畫質", "画質を上げる", "높은 화질", "Mayor calidad", "Qualité supérieure", "Höhere Qualität", "Qualidade superior", "جودة أعلى", "Высокое качество"),
    "fkuikit.video.settings.subtitles": _e("Subtitles", "字幕", "字幕", "字幕", "자막", "Subtítulos", "Sous-titres", "Untertitel", "Legendas", "الترجمات", "Субтитры"),
    "fkuikit.video.settings.subtitles_title": _e("Subtitles", "字幕", "字幕", "字幕", "자막", "Subtítulos", "Sous-titres", "Untertitel", "Legendas", "الترجمات", "Субтитры"),
    "fkuikit.video.settings.subtitles_off": _e("Off", "关闭", "關閉", "オフ", "끄기", "Desactivado", "Désactivé", "Aus", "Desligado", "إيقاف", "Выкл."),
    "fkuikit.video.settings.audio_track": _e("Audio Track", "音轨", "音軌", "音声トラック", "오디오 트랙", "Pista de audio", "Piste audio", "Audiospur", "Faixa de áudio", "مسار الصوت", "Аудиодорожка"),
    "fkuikit.video.settings.audio_title": _e("Audio", "音频", "音訊", "音声", "오디오", "Audio", "Audio", "Audio", "Áudio", "الصوت", "Аудио"),
    "fkuikit.audio.queue.sequential": _e("Sequential", "顺序播放", "順序播放", "順次", "순차", "Secuencial", "Séquentiel", "Sequenziell", "Sequencial", "تسلسلي", "Последовательно"),
    "fkuikit.audio.queue.shuffle": _e("Shuffle", "随机播放", "隨機播放", "シャッフル", "셔플", "Aleatorio", "Aléatoire", "Zufällig", "Aleatório", "عشوائي", "Случайно"),
    "fkuikit.audio.queue.repeat_all": _e("Repeat all", "列表循环", "列表循環", "すべてリピート", "전체 반복", "Repetir todo", "Tout répéter", "Alle wiederholen", "Repetir tudo", "تكرار الكل", "Повторять все"),
    "fkuikit.audio.queue.repeat_one": _e("Repeat one", "单曲循环", "單曲循環", "1曲リピート", "한 곡 반복", "Repetir una", "Répéter une", "Einen wiederholen", "Repetir uma", "تكرار واحدة", "Повторять одну"),
    "fkuikit.audio.queue.mode_label": _e("Queue mode", "队列模式", "佇列模式", "キューモード", "큐 모드", "Modo de cola", "Mode file", "Warteschlangenmodus", "Modo da fila", "وضع القائمة", "Режим очереди"),
    "fkuikit.audio.queue.mode_toast": _e("Queue mode: %@", "队列模式：%@", "佇列模式：%@", "キューモード：%@", "큐 모드: %@",
        "Modo de cola: %@", "Mode file : %@", "Warteschlangenmodus: %@", "Modo da fila: %@", "وضع القائمة: %@", "Режим очереди: %@"),
    "fkuikit.audio.unknown_title": _e("Unknown Title", "未知标题", "未知標題", "不明なタイトル", "알 수 없는 제목", "Título desconocido", "Titre inconnu", "Unbekannter Titel", "Título desconhecido", "عنوان غير معروف", "Неизвестное название"),
    "fkuikit.audio.unknown_artist": _e("Unknown Artist", "未知艺术家", "未知藝人", "不明なアーティスト", "알 수 없는 아티스트", "Artista desconocido", "Artiste inconnu", "Unbekannter Künstler", "Artista desconhecido", "فنان غير معروف", "Неизвестный исполнитель"),
    "fkuikit.audio.sleep_timer_set": _e("Sleep timer set for 30 minutes", "睡眠定时已设为 30 分钟", "睡眠定時已設為 30 分鐘", "スリープタイマーを30分に設定", "수면 타이머 30분 설정",
        "Temporizador de sueño: 30 min", "Minuterie : 30 min", "Schlaf-Timer: 30 Min.", "Timer de sono: 30 min", "مؤقت النوم: 30 دقيقة", "Таймер сна: 30 мин"),
    "fkuikit.actionsheet.error.no_actions": _e("Add at least one action before presenting the action sheet.", "展示操作表前请至少添加一个操作。", "展示操作表前請至少新增一個操作。", "アクションシートを表示する前に操作を追加してください。", "시트를 표시하기 전에 작업을 하나 이상 추가하세요.",
        "Añade al menos una acción.", "Ajoutez au moins une action.", "Mindestens eine Aktion hinzufügen.", "Adicione pelo menos uma ação.", "أضف إجراءً واحدًا على الأقل.", "Добавьте хотя бы одно действие."),
    "fkuikit.actionsheet.error.empty_loading": _e("Enable the activity indicator or provide loading title or message text.", "请启用活动指示器或提供加载标题/消息。", "請啟用活動指示器或提供載入標題/訊息。", "インジケーターを有効にするか、読み込みテキストを指定してください。", "인디케이터를 켜거나 로딩 텍스트를 제공하세요.",
        "Activa el indicador o proporciona texto de carga.", "Activez l'indicateur ou fournissez un texte.", "Indikator aktivieren oder Ladetext angeben.", "Ative o indicador ou forneça texto.", "فعّل المؤشر أو قدم نص التحميل.", "Включите индикатор или укажите текст."),
    "fkuikit.actionsheet.error.multiple_cancel": _e("Only one cancel action is allowed.", "只允许一个取消操作。", "只允許一個取消操作。", "キャンセル操作は1つのみです。", "취소 작업은 하나만 허용됩니다.",
        "Solo se permite una acción de cancelar.", "Une seule action d'annulation.", "Nur eine Abbrechen-Aktion.", "Apenas uma ação de cancelar.", "يُسمح بإجراء إلغاء واحد فقط.", "Разрешено только одно действие «Отмена»."),
    "fkuikit.actionsheet.error.presenter_not_found": _e("No presenter view controller was found.", "未找到展示控制器。", "未找到展示控制器。", "プレゼンターが見つかりません。", "표시 컨트롤러를 찾을 수 없습니다.",
        "No se encontró el controlador presentador.", "Aucun présentateur trouvé.", "Kein Presenter gefunden.", "Controlador apresentador não encontrado.", "لم يُعثر على المتحكم.", "Контроллер не найден."),
    "fkuikit.actionsheet.error.popover_anchor": _e("Popover presentation requires an anchor view or bar button item.", "Popover 展示需要锚点视图或栏按钮。", "Popover 展示需要錨點視圖或列按鈕。", "ポップオーバーにはアンカーが必要です。", "Popover에는 앵커가 필요합니다.",
        "El popover requiere una vista ancla.", "Le popover nécessite une ancre.", "Popover benötigt einen Anker.", "Popover requer âncora.", "يتطلب Popover مرساة.", "Popover требует якорь."),
    "fkuikit.actionsheet.error.already_presented": _e("This action sheet is already presented.", "操作表已在展示中。", "操作表已在展示中。", "アクションシートは既に表示されています。", "시트가 이미 표시 중입니다.",
        "La hoja de acciones ya está visible.", "La feuille est déjà affichée.", "Action Sheet bereits angezeigt.", "Folha já apresentada.", "ورقة الإجراءات معروضة بالفعل.", "Action Sheet уже показан."),
    "fkuikit.actionsheet.error.selection_exceeds_max": _e("Too many items are selected for this sheet's maximum. Deselect some choices first.", "选择项超过上限，请先取消部分选择。", "選擇項超過上限，請先取消部分選擇。", "選択数が上限を超えています。", "선택 항목이 최대치를 초과했습니다.",
        "Demasiados elementos seleccionados.", "Trop d'éléments sélectionnés.", "Zu viele Auswahlen.", "Muitos itens selecionados.", "تم تحديد عناصر كثيرة جدًا.", "Слишком много выбранных элементов."),
    "fkuikit.actionsheet.error.unknown_selection": _e("A pre-selected action ID is not in this sheet.", "预选操作 ID 不在此表中。", "預選操作 ID 不在此表中。", "事前選択された ID がこのシートにありません。", "사전 선택 ID가 시트에 없습니다.",
        "El ID preseleccionado no está en la hoja.", "L'ID présélectionné n'est pas dans la feuille.", "Vorausgewählte ID nicht in Sheet.", "ID pré-selecionado ausente.", "المعرّف المحدد مسبقًا غير موجود.", "Предвыбранный ID отсутствует."),
    "fkuikit.empty.permissionDenied.title": _e("Access denied", "无权限访问", "無權限存取", "アクセス拒否", "접근 거부", "Acceso denegado", "Accès refusé", "Zugriff verweigert", "Acesso negado", "تم رفض الوصول", "Доступ запрещён"),
    "fkuikit.empty.permissionDenied.description": _e("You don't have permission to view this content.", "你没有权限查看此内容。", "你沒有權限查看此內容。", "このコンテンツを表示する権限がありません。", "이 콘텐츠를 볼 권한이 없습니다.",
        "No tienes permiso para ver este contenido.", "Vous n'avez pas la permission.", "Keine Berechtigung.", "Sem permissão para ver.", "ليس لديك إذن.", "Нет разрешения."),
    "fkuikit.empty.notFound.title": _e("Not found", "未找到", "未找到", "見つかりません", "찾을 수 없음", "No encontrado", "Introuvable", "Nicht gefunden", "Não encontrado", "غير موجود", "Не найдено"),
    "fkuikit.empty.notFound.description": _e("The requested resource doesn't exist.", "请求的资源不存在。", "請求的資源不存在。", "要求されたリソースは存在しません。", "요청한 리소스가 없습니다.",
        "El recurso solicitado no existe.", "La ressource n'existe pas.", "Ressource existiert nicht.", "Recurso não existe.", "المورد غير موجود.", "Ресурс не существует."),
    "fkuikit.empty.maintenance.title": _e("Under maintenance", "维护中", "維護中", "メンテナンス中", "점검 중", "En mantenimiento", "En maintenance", "Wartung", "Em manutenção", "تحت الصيانة", "На обслуживании"),
    "fkuikit.empty.maintenance.description": _e("We're performing scheduled maintenance. Please try again later.", "正在进行计划维护，请稍后再试。", "正在進行計劃維護，請稍後再試。", "定期メンテナンス中です。後でもう一度お試しください。", "정기 점검 중입니다. 나중에 다시 시도하세요.",
        "Mantenimiento programado. Inténtalo más tarde.", "Maintenance planifiée.", "Geplante Wartung.", "Manutenção programada.", "صيانة مجدولة.", "Плановое обслуживание."),
    "fkuikit.empty.loading.title": _e("Loading", "加载中", "載入中", "読み込み中", "로딩 중", "Cargando", "Chargement", "Wird geladen", "Carregando", "جارٍ التحميل", "Загрузка"),
    "fkuikit.empty.loading.description": _e("Please wait…", "请稍候…", "請稍候…", "お待ちください…", "잠시 기다려 주세요…", "Espera…", "Veuillez patienter…", "Bitte warten…", "Aguarde…", "يرجى الانتظار…", "Подождите…"),
    "fkuikit.empty.newUser.title": _e("Welcome", "欢迎", "歡迎", "ようこそ", "환영합니다", "Bienvenido", "Bienvenue", "Willkommen", "Bem-vindo", "مرحبًا", "Добро пожаловать"),
    "fkuikit.empty.newUser.description": _e("Let's get you started.", "让我们开始吧。", "讓我們開始吧。", "さあ、始めましょう。", "시작해 볼까요?", "Empecemos.", "Commençons.", "Legen wir los.", "Vamos começar.", "لنبدأ.", "Начнём."),
    "fkuikit.empty.action.clearFilters": _e("Clear filters", "清空筛选", "清空篩選", "フィルターをクリア", "필터 지우기", "Borrar filtros", "Effacer les filtres", "Filter löschen", "Limpar filtros", "مسح المرشحات", "Сбросить фильтры"),
    "fkuikit.empty.action.create": _e("Create", "创建", "建立", "作成", "만들기", "Crear", "Créer", "Erstellen", "Criar", "إنشاء", "Создать"),
    "fkuikit.empty.action.contactAdmin": _e("Contact admin", "联系管理员", "聯繫管理員", "管理者に連絡", "관리자에게 문의", "Contactar admin", "Contacter l'admin", "Admin kontaktieren", "Contatar admin", "اتصل بالمسؤول", "Связаться с админом"),
    "fkuikit.empty.action.learnMore": _e("Learn more", "了解更多", "了解更多", "詳細を見る", "자세히 보기", "Más información", "En savoir plus", "Mehr erfahren", "Saiba mais", "اعرف المزيد", "Подробнее"),
    "fkuikit.empty.scenario.no_network.title": _e("No network", "无网络", "無網路", "ネットワークなし", "네트워크 없음", "Sin red", "Pas de réseau", "Kein Netzwerk", "Sem rede", "لا توجد شبكة", "Нет сети"),
    "fkuikit.empty.scenario.no_network.description": _e("Check your connection and try again.", "请检查连接后重试。", "請檢查連線後重試。", "接続を確認して再試行してください。", "연결을 확인하고 다시 시도하세요.",
        "Comprueba tu conexión.", "Vérifiez votre connexion.", "Verbindung prüfen.", "Verifique a conexão.", "تحقق من الاتصال.", "Проверьте подключение."),
    "fkuikit.empty.scenario.no_network.action": _e("Reload", "重新加载", "重新載入", "再読み込み", "새로고침", "Recargar", "Recharger", "Neu laden", "Recarregar", "إعادة التحميل", "Перезагрузить"),
    "fkuikit.empty.scenario.no_search.description": _e("Try different keywords.", "请尝试其他关键词。", "請嘗試其他關鍵詞。", "別のキーワードをお試しください。", "다른 키워드를 시도하세요.",
        "Prueba otras palabras clave.", "Essayez d'autres mots-clés.", "Andere Stichwörter versuchen.", "Tente outras palavras-chave.", "جرّب كلمات مختلفة.", "Попробуйте другие слова."),
    "fkuikit.empty.scenario.no_favorites.title": _e("No favorites yet", "暂无收藏", "暫無收藏", "お気に入りはまだありません", "즐겨찾기 없음", "Sin favoritos", "Pas de favoris", "Noch keine Favoriten", "Sem favoritos", "لا توجد مفضلات", "Нет избранного"),
    "fkuikit.empty.scenario.no_favorites.description": _e("Save items you like to see them here.", "收藏喜欢的内容即可在此查看。", "收藏喜歡的內容即可在此查看。", "お気に入りを保存するとここに表示されます。", "좋아하는 항목을 저장하세요.",
        "Guarda lo que te gusta.", "Enregistrez vos favoris.", "Favoriten speichern.", "Salve seus favoritos.", "احفظ ما يعجبك.", "Сохраняйте понравившееся."),
    "fkuikit.empty.scenario.no_favorites.action": _e("Go home", "返回首页", "返回首頁", "ホームへ", "홈으로", "Ir al inicio", "Accueil", "Zur Startseite", "Ir para início", "الصفحة الرئيسية", "На главную"),
    "fkuikit.empty.scenario.no_orders.title": _e("No orders", "暂无订单", "暫無訂單", "注文はありません", "주문 없음", "Sin pedidos", "Pas de commandes", "Keine Bestellungen", "Sem pedidos", "لا توجد طلبات", "Нет заказов"),
    "fkuikit.empty.scenario.no_orders.description": _e("Place an order to track it here.", "下单后可在此跟踪。", "下單後可在此追蹤。", "注文するとここで追跡できます。", "주문하면 여기서 추적할 수 있습니다.",
        "Haz un pedido para rastrearlo.", "Passez commande pour suivre.", "Bestellen zum Verfolgen.", "Faça um pedido.", "قدّم طلبًا للتتبع.", "Оформите заказ."),
    "fkuikit.empty.scenario.no_orders.action": _e("Shop now", "去购物", "去購物", "今すぐ購入", "쇼핑하기", "Comprar ahora", "Acheter", "Jetzt einkaufen", "Comprar agora", "تسوق الآن", "Купить"),
    "fkuikit.empty.scenario.no_messages.title": _e("No messages", "暂无消息", "暫無訊息", "メッセージはありません", "메시지 없음", "Sin mensajes", "Pas de messages", "Keine Nachrichten", "Sem mensagens", "لا توجد رسائل", "Нет сообщений"),
    "fkuikit.empty.scenario.no_messages.description": _e("New notifications will appear here.", "新通知将显示在这里。", "新通知將顯示在這裡。", "新しい通知がここに表示されます。", "새 알림이 여기에 표시됩니다.",
        "Las notificaciones aparecerán aquí.", "Les notifications apparaîtront ici.", "Benachrichtigungen erscheinen hier.", "Notificações aparecerão aqui.", "ستظهر الإشعارات هنا.", "Уведомления появятся здесь."),
    "fkuikit.empty.scenario.load_failed.title": _e("Couldn't load", "加载失败", "載入失敗", "読み込めませんでした", "로드 실패", "No se pudo cargar", "Chargement impossible", "Laden fehlgeschlagen", "Não foi possível carregar", "تعذر التحميل", "Не удалось загрузить"),
    "fkuikit.empty.scenario.load_failed.description": _e("The request timed out or the server returned an error. Try again.", "请求超时或服务器出错，请重试。", "請求逾時或伺服器出錯，請重試。", "タイムアウトまたはサーバーエラー。再試行してください。", "요청 시간 초과 또는 서버 오류. 다시 시도하세요.",
        "Tiempo agotado o error del servidor.", "Délai dépassé ou erreur serveur.", "Timeout oder Serverfehler.", "Tempo esgotado ou erro.", "انتهت المهلة أو خطأ.", "Таймаут или ошибка сервера."),
    "fkuikit.empty.scenario.no_permission.title": _e("No access", "无访问权限", "無存取權限", "アクセス不可", "접근 불가", "Sin acceso", "Pas d'accès", "Kein Zugriff", "Sem acesso", "لا يوجد وصول", "Нет доступа"),
    "fkuikit.empty.scenario.not_logged_in.title": _e("Sign in required", "需要登录", "需要登入", "サインインが必要", "로그인 필요", "Inicio de sesión requerido", "Connexion requise", "Anmeldung erforderlich", "Login necessário", "تسجيل الدخول مطلوب", "Требуется вход"),
    "fkuikit.empty.scenario.not_logged_in.description": _e("Log in to see your data here.", "登录后即可在此查看数据。", "登入後即可在此查看資料。", "サインインしてデータを表示。", "로그인하면 데이터를 볼 수 있습니다.",
        "Inicia sesión para ver tus datos.", "Connectez-vous pour voir vos données.", "Anmelden für Daten.", "Faça login para ver.", "سجّل الدخول.", "Войдите для просмотра."),
    "fkuikit.empty.scenario.not_logged_in.action": _e("Sign in", "登录", "登入", "サインイン", "로그인", "Iniciar sesión", "Se connecter", "Anmelden", "Entrar", "تسجيل الدخول", "Войти"),
    "fkuikit.video.live_badge": _e("LIVE", "直播", "直播", "ライブ", "라이브", "EN VIVO", "DIRECT", "LIVE", "AO VIVO", "مباشر", "ЭФИР"),
    "fkuikit.video.go_live": _e("Go Live", "跳到直播", "跳到直播", "ライブへ", "라이브로", "Ir en vivo", "Aller en direct", "Zum Live", "Ir ao vivo", "انتقل للبث", "К эфиру"),
    "fkuikit.video.live_latency": _e("LIVE · ~%.0fs", "直播 · ~%.0f秒", "直播 · ~%.0f秒", "ライブ · ~%.0f秒", "라이브 · ~%.0f초", "EN VIVO · ~%.0f s", "DIRECT · ~%.0f s", "LIVE · ~%.0f s", "AO VIVO · ~%.0f s", "مباشر · ~%.0f ث", "ЭФИР · ~%.0f с"),
    "fkuikit.video.unknown_title": _e("Video", "视频", "影片", "動画", "동영상", "Vídeo", "Vidéo", "Video", "Vídeo", "فيديو", "Видео"),
    "fkuikit.video.advertisement": _e("Advertisement", "广告", "廣告", "広告", "광고", "Anuncio", "Publicité", "Werbung", "Anúncio", "إعلان", "Реклама"),
    "fkuikit.audio.waveform.url_only": _e(
        "Only URL-based assets are supported for waveform extraction.", "仅支持基于 URL 的资源提取波形。", "僅支援基於 URL 的資源提取波形。", "波形抽出は URL ベースのアセットのみサポートします。", "URL 기반 에셋만 파형 추출을 지원합니다.",
        "Solo se admiten activos basados en URL.", "Seuls les assets URL sont pris en charge.", "Nur URL-basierte Assets unterstützt.", "Apenas recursos baseados em URL.", "الأصول المعتمدة على URL فقط.", "Поддерживаются только URL-ресурсы."),
    "fkuikit.audio.waveform.reader_start_failed": _e(
        "AVAssetReader could not start.", "AVAssetReader 无法启动。", "AVAssetReader 無法啟動。", "AVAssetReader を開始できませんでした。", "AVAssetReader를 시작할 수 없습니다.",
        "AVAssetReader no pudo iniciarse.", "AVAssetReader n'a pas pu démarrer.", "AVAssetReader konnte nicht starten.", "AVAssetReader não iniciou.", "تعذر بدء AVAssetReader.", "AVAssetReader не удалось запустить."),
    "fkuikit.audio.waveform.reader_failed": _e(
        "AVAssetReader failed.", "AVAssetReader 失败。", "AVAssetReader 失敗。", "AVAssetReader に失敗しました。", "AVAssetReader 실패.",
        "AVAssetReader falló.", "Échec d'AVAssetReader.", "AVAssetReader fehlgeschlagen.", "AVAssetReader falhou.", "فشل AVAssetReader.", "AVAssetReader не удался."),
    "fkuikit.audio.waveform.no_samples": _e(
        "No PCM samples were decoded.", "未解码 PCM 样本。", "未解碼 PCM 樣本。", "PCM サンプルがデコードされませんでした。", "PCM 샘플이 디코딩되지 않았습니다.",
        "No se decodificaron muestras PCM.", "Aucun échantillon PCM décodé.", "Keine PCM-Samples decodiert.", "Nenhuma amostra PCM decodificada.", "لم يتم فك PCM.", "PCM-сэмплы не декодированы."),
    "fkuikit.audio.waveform.zero_peaks": _e(
        "Waveform peaks are zero.", "波形峰值为零。", "波形峰值為零。", "波形ピークがゼロです。", "파형 피크가 0입니다.",
        "Los picos de forma de onda son cero.", "Les pics sont nuls.", "Wellenform-Peaks sind null.", "Picos da forma de onda são zero.", "قيم الموجة صفر.", "Пики волны равны нулю."),
    "fkuikit.audio.waveform.no_audio_track": _e(
        "No audio track found.", "未找到音轨。", "未找到音軌。", "オーディオトラックが見つかりません。", "오디오 트랙을 찾을 수 없습니다.",
        "No se encontró pista de audio.", "Aucune piste audio.", "Keine Audiospur gefunden.", "Faixa de áudio não encontrada.", "لم يُعثر على مسار صوت.", "Аудиодорожка не найдена."),
    "fkuikit.audio.waveform.unreadable_asset": _e(
        "Asset is not readable.", "资源不可读。", "資源不可讀。", "アセットを読み取れません。", "에셋을 읽을 수 없습니다.",
        "El recurso no es legible.", "Ressource illisible.", "Asset nicht lesbar.", "Recurso não legível.", "الأصل غير قابل للقراءة.", "Ресурс не читается."),
    "fkuikit.media.error.no_active_player": _e(
        "No active player.", "无活动播放器。", "無作用中播放器。", "アクティブなプレイヤーがありません。", "활성 플레이어 없음.",
        "No hay reproductor activo.", "Aucun lecteur actif.", "Kein aktiver Player.", "Nenhum player ativo.", "لا يوجد مشغل نشط.", "Нет активного плеера."),
    "fkuikit.media.error.no_current_item": _e(
        "No current item.", "无当前项目。", "無目前項目。", "現在のアイテムがありません。", "현재 항목 없음.",
        "No hay elemento actual.", "Aucun élément actuel.", "Kein aktuelles Element.", "Nenhum item atual.", "لا يوجد عنصر حالي.", "Нет текущего элемента."),
    "fkuikit.media.error.offline_asset_not_found": _e(
        "Offline asset not found for id: %@", "未找到离线资源：%@", "未找到離線資源：%@", "オフラインアセットが見つかりません：%@", "오프라인 에셋을 찾을 수 없음: %@",
        "Recurso offline no encontrado: %@", "Ressource hors ligne introuvable : %@", "Offline-Asset nicht gefunden: %@", "Recurso offline não encontrado: %@", "الأصل غير متصل غير موجود: %@", "Офлайн-ресурс не найден: %@"),
    "fkuikit.media.error.playlist_empty": _e(
        "Playlist is empty.", "播放列表为空。", "播放清單為空。", "プレイリストが空です。", "재생 목록이 비어 있습니다.",
        "La lista está vacía.", "La playlist est vide.", "Playlist ist leer.", "Playlist vazia.", "قائمة التشغيل فارغة.", "Плейлист пуст."),
    "fkuikit.media.error.no_url_for_probe": _e(
        "Media source has no URL for format probing.", "媒体源无 URL 可用于格式探测。", "媒體來源無 URL 可用於格式偵測。", "メディアソースに形式プローブ用 URL がありません。", "미디어 소스에 형식 프로브 URL 없음.",
        "La fuente no tiene URL para sondeo.", "La source n'a pas d'URL.", "Medienquelle hat keine URL.", "Fonte sem URL para sondagem.", "المصدر ليس له URL.", "У источника нет URL."),
    "fkuikit.media.error.photo_not_found": _e(
        "Photo asset not found: %@", "未找到照片资源：%@", "未找到照片資源：%@", "写真アセットが見つかりません：%@", "사진 에셋을 찾을 수 없음: %@",
        "Foto no encontrada: %@", "Photo introuvable : %@", "Foto nicht gefunden: %@", "Foto não encontrada: %@", "الصورة غير موجودة: %@", "Фото не найдено: %@"),
    "fkuikit.media.error.photo_not_url_asset": _e(
        "Photo asset is not exported as AVURLAsset.", "照片资源未导出为 AVURLAsset。", "照片資源未匯出為 AVURLAsset。", "写真アセットが AVURLAsset としてエクスポートされていません。", "사진 에셋이 AVURLAsset으로 내보내지지 않았습니다.",
        "La foto no se exportó como AVURLAsset.", "La photo n'est pas exportée en AVURLAsset.", "Foto nicht als AVURLAsset exportiert.", "Foto não exportada como AVURLAsset.", "الصورة لم تُصدَّر كـ AVURLAsset.", "Фото не экспортировано как AVURLAsset."),
    "fkuikit.progressbar.sample_title": _e("Title", "标题", "標題", "タイトル", "제목", "Título", "Titre", "Titel", "Título", "العنوان", "Заголовок"),
    "fkuikit.video.debug.llhls.title": _e("LL-HLS Debug", "LL-HLS 调试", "LL-HLS 除錯", "LL-HLS デバッグ", "LL-HLS 디버그", "Depuración LL-HLS", "Debug LL-HLS", "LL-HLS-Debug", "Depuração LL-HLS", "Depuración LL-HLS", "Отладка LL-HLS"),
    "fkuikit.video.debug.llhls.latency": _e("latency: %@", "延迟：%@", "延遲：%@", "latency: %@", "지연: %@", "latencia: %@", "latence : %@", "Latenz: %@", "latência: %@", "الزمن: %@", "задержка: %@"),
    "fkuikit.video.debug.llhls.buffer": _e("buffer: %@s", "缓冲：%@秒", "緩衝：%@秒", "buffer: %@s", "버퍼: %@s", "búfer: %@ s", "tampon : %@ s", "Puffer: %@ s", "buffer: %@ s", "المخزن: %@ ث", "буфер: %@ с"),
    "fkuikit.video.debug.llhls.state": _e("state: %@", "状态：%@", "狀態：%@", "state: %@", "상태: %@", "estado: %@", "état : %@", "Status: %@", "estado: %@", "الحالة: %@", "состояние: %@"),
    "fkuikit.media.delivery.file": _e("file", "文件", "檔案", "ファイル", "파일", "archivo", "fichier", "Datei", "arquivo", "ملف", "файл"),
    "fkuikit.media.delivery.progressive_http": _e("progressive HTTP", "渐进式 HTTP", "漸進式 HTTP", "プログレッシブ HTTP", "점진적 HTTP", "HTTP progresivo", "HTTP progressif", "Progressives HTTP", "HTTP progressivo", "HTTP تدريجي", "прогрессивный HTTP"),
    "fkuikit.media.delivery.hls_vod": _e("HLS VOD", "HLS 点播", "HLS 點播", "HLS VOD", "HLS VOD", "HLS VOD", "HLS VOD", "HLS VOD", "HLS VOD", "HLS VOD", "HLS VOD"),
    "fkuikit.media.delivery.hls_live": _e("HLS live", "HLS 直播", "HLS 直播", "HLS ライブ", "HLS 라이브", "HLS en vivo", "HLS direct", "HLS Live", "HLS ao vivo", "HLS مباشر", "HLS эфир"),
    "fkuikit.media.delivery.rtmp": _e("RTMP", "RTMP", "RTMP", "RTMP", "RTMP", "RTMP", "RTMP", "RTMP", "RTMP", "RTMP", "RTMP"),
    "fkuikit.media.delivery.rtsp": _e("RTSP", "RTSP", "RTSP", "RTSP", "RTSP", "RTSP", "RTSP", "RTSP", "RTSP", "RTSP", "RTSP"),
    "fkuikit.media.delivery.dash": _e("DASH", "DASH", "DASH", "DASH", "DASH", "DASH", "DASH", "DASH", "DASH", "DASH", "DASH"),
    "fkuikit.media.delivery.http_flv": _e("HTTP-FLV", "HTTP-FLV", "HTTP-FLV", "HTTP-FLV", "HTTP-FLV", "HTTP-FLV", "HTTP-FLV", "HTTP-FLV", "HTTP-FLV", "HTTP-FLV", "HTTP-FLV"),
    "fkuikit.video.subtitle.error.invalid_encoding": _e(
        "Subtitle file encoding is not supported.", "不支持的字幕文件编码。", "不支援的字幕檔案編碼。", "字幕ファイルのエンコードがサポートされていません。", "지원되지 않는 자막 파일 인코딩.",
        "Codificación de subtítulos no compatible.", "Encodage de sous-titres non pris en charge.", "Untertitel-Kodierung nicht unterstützt.", "Codificação de legendas não suportada.", "ترميز ملف الترجمة غير مدعوم.", "Кодировка субтитров не поддерживается."),
    "fkuikit.audio.lyrics.error.invalid_encoding": _e(
        "Lyrics file encoding is not supported.", "不支持的歌词文件编码。", "不支援的歌詞檔案編碼。", "歌詞ファイルのエンコードがサポートされていません。", "지원되지 않는 가사 파일 인코딩.",
        "Codificación de letras no compatible.", "Encodage des paroles non pris en charge.", "Liedtext-Kodierung nicht unterstützt.", "Codificação de letras não suportada.", "ترميز ملف الكلمات غير مدعوم.", "Кодировка текста песни не поддерживается."),
}

# fmt: on
