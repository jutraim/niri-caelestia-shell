#pragma once

#include <qobject.h>
#include <QtQuick/QQuickItem>

class CUtils : public QObject {
    Q_OBJECT;
    QML_NAMED_ELEMENT(CUtils);
    QML_SINGLETON;

public:
<<<<<<< HEAD
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved, QJSValue onFailed);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed);
=======
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved, QJSValue onFailed) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed) const;

    Q_INVOKABLE bool copyFile(const QUrl& source, const QUrl& target) const;
    Q_INVOKABLE bool copyFile(const QUrl& source, const QUrl& target, bool overwrite) const;
>>>>>>> b5d8125 (internal: better copy)
};
