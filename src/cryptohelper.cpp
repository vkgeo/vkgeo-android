#include <QtCore/QtGlobal>
#include <QtCore/QLatin1Char>
#include <QtCore/QLatin1String>
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

QString CryptoHelper::sharedKey() const
{
    return SharedKey;
}

void CryptoHelper::setSharedKey(const QString &key)
{
    if (SharedKey != key) {
        SharedKey = key;

        emit sharedKeyChanged(SharedKey);
    }
}

QVariantMap CryptoHelper::sharedKeysOfFriends() const
{
    return SharedKeysOfFriends;
}

void CryptoHelper::setSharedKeysOfFriends(const QVariantMap &keys)
{
    if (SharedKeysOfFriends != keys) {
        SharedKeysOfFriends = keys;

        emit sharedKeysOfFriendsChanged(SharedKeysOfFriends);
    }
}

void CryptoHelper::regenerateSharedKey()
{
    SharedKey = GenerateRandomString(SHARED_KEY_LENGTH);

    emit sharedKeyChanged(SharedKey);
}

QString CryptoHelper::getSharedKeyOfFriend(const QString &friend_user_id) const
{
    if (SharedKeysOfFriends.contains(friend_user_id)) {
        return SharedKeysOfFriends[friend_user_id].toString();
    } else {
        return QLatin1String("");
    }
}

void CryptoHelper::setSharedKeyOfFriend(const QString &friend_user_id, const QString &friend_key)
{
    if (friend_user_id != QLatin1String("") && (!SharedKeysOfFriends.contains(friend_user_id) ||
                                                 SharedKeysOfFriends[friend_user_id] != friend_key)) {
        SharedKeysOfFriends[friend_user_id] = friend_key;

        emit sharedKeysOfFriendsChanged(SharedKeysOfFriends);
    }
}

void CryptoHelper::removeSharedKeyOfFriend(const QString &friend_user_id)
{
    if (SharedKeysOfFriends.contains(friend_user_id)) {
        SharedKeysOfFriends.remove(friend_user_id);

        emit sharedKeysOfFriendsChanged(SharedKeysOfFriends);
    }
}

void CryptoHelper::clearSharedKeysOfFriends()
{
    if (!SharedKeysOfFriends.isEmpty()) {
        SharedKeysOfFriends.clear();

        emit sharedKeysOfFriendsChanged(SharedKeysOfFriends);
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
    QString key = QLatin1String("");

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
