#include <cstdlib>

#include <QtCore/QLatin1String>
#include <QtCore/QDebug>

#include <sodium.h>

#include "cryptohelper.h"

CryptoHelper::CryptoHelper(QObject *parent) :
    QObject(parent)
{
    if (sodium_init() < 0) {
        qCritical() << "CryptoHelper() : sodium_init() failed";

        abort();
    }
}

CryptoHelper &CryptoHelper::GetInstance()
{
    static CryptoHelper instance;

    return instance;
}

QString CryptoHelper::publicKey() const
{
    return PublicKey;
}

void CryptoHelper::setPublicKey(const QString &key)
{
    if (PublicKey != key) {
        PublicKey = key;

        emit publicKeyChanged(PublicKey);
    }
}

QString CryptoHelper::privateKey() const
{
    return PrivateKey;
}

void CryptoHelper::setPrivateKey(const QString &key)
{
    if (PrivateKey != key) {
        PrivateKey = key;

        emit privateKeyChanged(PrivateKey);
    }
}

QVariantMap CryptoHelper::publicKeysOfFriends() const
{
    return PublicKeysOfFriends;
}

void CryptoHelper::setPublicKeysOfFriends(const QVariantMap &keys)
{
    if (PublicKeysOfFriends != keys) {
        PublicKeysOfFriends = keys;

        emit publicKeysOfFriendsChanged(PublicKeysOfFriends);
    }
}

bool CryptoHelper::validateKeyPair(const QString &public_key, const QString &private_key) const
{
    const QByteArray text("TEXT FOR KEY PAIR VALIDATION");

    const QByteArray raw_public_key  = QByteArray::fromBase64(public_key.toUtf8()),
                     raw_private_key = QByteArray::fromBase64(private_key.toUtf8());

    QByteArray encrypted(text.size() + crypto_box_SEALBYTES, 0),
               decrypted(text.size(),                        0);

    return (raw_public_key.size()  == crypto_box_PUBLICKEYBYTES &&
            raw_private_key.size() == crypto_box_SECRETKEYBYTES &&
            crypto_box_seal(reinterpret_cast<unsigned char *>(encrypted.data()),
                            reinterpret_cast<const unsigned char *>(text.data()),
                            text.size(),
                            reinterpret_cast<const unsigned char *>(raw_public_key.data())) == 0 &&
            crypto_box_seal_open(reinterpret_cast<unsigned char *>(decrypted.data()),
                                 reinterpret_cast<unsigned char *>(encrypted.data()),
                                 encrypted.size(),
                                 reinterpret_cast<const unsigned char *>(raw_public_key.data()),
                                 reinterpret_cast<const unsigned char *>(raw_private_key.data())) == 0 &&
            text == decrypted);
}

void CryptoHelper::regenerateKeyPair()
{
    QByteArray raw_public_key (crypto_box_PUBLICKEYBYTES, 0),
               raw_private_key(crypto_box_SECRETKEYBYTES, 0);

    if (crypto_box_keypair(reinterpret_cast<unsigned char *>(raw_public_key.data()),
                           reinterpret_cast<unsigned char *>(raw_private_key.data())) == 0) {
        QString public_key  = QString::fromUtf8(raw_public_key.toBase64());
        QString private_key = QString::fromUtf8(raw_private_key.toBase64());

        if (PublicKey != public_key) {
            PublicKey = public_key;

            emit publicKeyChanged(PublicKey);
        }
        if (PrivateKey != private_key) {
            PrivateKey = private_key;

            emit privateKeyChanged(PrivateKey);
        }
    } else {
        qWarning() << "regenerateKeyPair() : crypto_box_keypair() failed";
    }
}

QString CryptoHelper::getPublicKeyOfFriend(const QString &friend_user_id) const
{
    if (PublicKeysOfFriends.contains(friend_user_id)) {
        return PublicKeysOfFriends[friend_user_id].toString();
    } else {
        return QLatin1String("");
    }
}

void CryptoHelper::setPublicKeyOfFriend(const QString &friend_user_id, const QString &friend_key)
{
    if (friend_user_id != QLatin1String("") && (!PublicKeysOfFriends.contains(friend_user_id) ||
                                                 PublicKeysOfFriends[friend_user_id] != friend_key)) {
        PublicKeysOfFriends[friend_user_id] = friend_key;

        emit publicKeysOfFriendsChanged(PublicKeysOfFriends);
    }
}

void CryptoHelper::removePublicKeyOfFriend(const QString &friend_user_id)
{
    if (PublicKeysOfFriends.contains(friend_user_id)) {
        PublicKeysOfFriends.remove(friend_user_id);

        emit publicKeysOfFriendsChanged(PublicKeysOfFriends);
    }
}

void CryptoHelper::clearPublicKeysOfFriends()
{
    if (!PublicKeysOfFriends.isEmpty()) {
        PublicKeysOfFriends.clear();

        emit publicKeysOfFriendsChanged(PublicKeysOfFriends);
    }
}

QByteArray CryptoHelper::EncryptWithSealedBox(const QString &public_key, const QByteArray &payload) const
{
    const QByteArray raw_public_key = QByteArray::fromBase64(public_key.toUtf8());

    QByteArray result(payload.size() + crypto_box_SEALBYTES, 0);

    if (raw_public_key.size() == crypto_box_PUBLICKEYBYTES &&
        crypto_box_seal(reinterpret_cast<unsigned char *>(result.data()),
                        reinterpret_cast<const unsigned char *>(payload.data()),
                        payload.size(),
                        reinterpret_cast<const unsigned char *>(raw_public_key.data())) == 0) {
        return result;
    } else {
        return QByteArray();
    }
}

QByteArray CryptoHelper::DecryptSealedBox(const QString &public_key, const QString &private_key, const QByteArray &encrypted_payload) const
{
    const QByteArray raw_public_key  = QByteArray::fromBase64(public_key.toUtf8()),
                     raw_private_key = QByteArray::fromBase64(private_key.toUtf8());

    QByteArray result(encrypted_payload.size() - crypto_box_SEALBYTES, 0);

    if (raw_public_key.size()  == crypto_box_PUBLICKEYBYTES &&
        raw_private_key.size() == crypto_box_SECRETKEYBYTES &&
        crypto_box_seal_open(reinterpret_cast<unsigned char *>(result.data()),
                             reinterpret_cast<const unsigned char *>(encrypted_payload.data()),
                             encrypted_payload.size(),
                             reinterpret_cast<const unsigned char *>(raw_public_key.data()),
                             reinterpret_cast<const unsigned char *>(raw_private_key.data())) == 0) {
        return result;
    } else {
        return QByteArray();
    }
}
