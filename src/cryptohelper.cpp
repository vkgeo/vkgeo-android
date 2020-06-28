#include <QtCore/QtGlobal>
#include <QtCore/QLatin1Char>
#include <QtCore/QRandomGenerator>
#include <QtCore/QCryptographicHash>

#include <qt-aes/qaesencryption.h>

#include "cryptohelper.h"

CryptoHelper::CryptoHelper(QObject *parent) :
    QObject(parent)
{
}

CryptoHelper &CryptoHelper::GetInstance()
{
    static CryptoHelper instance;

    return instance;
}

QString CryptoHelper::encryptionKey() const
{
    return EncryptionKey;
}

void CryptoHelper::setEncryptionKey(const QString &key)
{
    if (EncryptionKey != key) {
        EncryptionKey = key;

        emit encryptionKeyChanged(EncryptionKey);
    }
}

QVariantMap CryptoHelper::friendsEncryptionKeys() const
{
    return FriendsEncryptionKeys;
}

void CryptoHelper::setFriendsEncryptionKeys(const QVariantMap &keys)
{
    if (FriendsEncryptionKeys != keys) {
        FriendsEncryptionKeys = keys;

        emit friendsEncryptionKeysChanged(FriendsEncryptionKeys);
    }
}

void CryptoHelper::regenerateEncryptionKey()
{
    EncryptionKey = GenerateRandomString(ENCRYPTION_KEY_LENGTH);

    emit encryptionKeyChanged(EncryptionKey);
}

QString CryptoHelper::getFriendEncryptionKey(const QString &friend_user_id) const
{
    if (FriendsEncryptionKeys.contains(friend_user_id)) {
        return FriendsEncryptionKeys[friend_user_id].toString();
    } else {
        return QStringLiteral("");
    }
}

void CryptoHelper::setFriendEncryptionKey(const QString &friend_user_id, const QString &friend_encryption_key)
{
    if (friend_user_id != QStringLiteral("") && (!FriendsEncryptionKeys.contains(friend_user_id) ||
                                                  FriendsEncryptionKeys[friend_user_id] != friend_encryption_key)) {
        FriendsEncryptionKeys[friend_user_id] = friend_encryption_key;

        emit friendsEncryptionKeysChanged(FriendsEncryptionKeys);
    }
}

void CryptoHelper::removeFriendEncryptionKey(const QString &friend_user_id)
{
    if (FriendsEncryptionKeys.contains(friend_user_id)) {
        FriendsEncryptionKeys.remove(friend_user_id);

        emit friendsEncryptionKeysChanged(FriendsEncryptionKeys);
    }
}

void CryptoHelper::clearFriendsEncryptionKeys()
{
    if (!FriendsEncryptionKeys.isEmpty()) {
        FriendsEncryptionKeys.clear();

        emit friendsEncryptionKeysChanged(FriendsEncryptionKeys);
    }
}

std::tuple<QString, QByteArray> CryptoHelper::EncryptWithAES256CBC(const QString &key, const QByteArray &payload) const
{
    QString iv = GenerateRandomString(AES_256_IV_LENGTH);

    QByteArray key_hash = QCryptographicHash::hash(key.toLatin1(), QCryptographicHash::Sha256);
    QByteArray iv_hash  = QCryptographicHash::hash(iv.toLatin1(),  QCryptographicHash::Md5);

    QAESEncryption aes(QAESEncryption::AES_256, QAESEncryption::CBC);

    return std::make_tuple(iv, aes.encode(payload, key_hash, iv_hash));
}

QByteArray CryptoHelper::DecryptAES256CBC(const QString &key, const QString &iv, const QByteArray &encrypted_payload) const
{
    QByteArray key_hash = QCryptographicHash::hash(key.toLatin1(), QCryptographicHash::Sha256);
    QByteArray iv_hash  = QCryptographicHash::hash(iv.toLatin1(),  QCryptographicHash::Md5);

    QAESEncryption aes(QAESEncryption::AES_256, QAESEncryption::CBC);

    return aes.removePadding(aes.decode(encrypted_payload, key_hash, iv_hash));
}

QString CryptoHelper::GenerateRandomString(int length) const
{
    QString key = QStringLiteral("");

    for (int i = 0; i < length;) {
        quint32 next_char = QRandomGenerator::system()->bounded('0', '{');

        if ((next_char >= '0' && next_char <= '9') ||
            (next_char >= 'A' && next_char <= 'Z') ||
            (next_char >= 'a' && next_char <= 'z')) {
            key.append(QLatin1Char(static_cast<char>(next_char)));

            i++;
        }
    }

    return key;
}
