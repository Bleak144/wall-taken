const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const serviceAccount = require('./service-account.json');

initializeApp({ credential: cert(serviceAccount) });

const [token, mode] = process.argv.slice(2);
if (!token) {
  console.error('Uso: node send.js "<TOKEN>" [notif]');
  process.exit(1);
}

const message = {
  token,
  data: {
    type: 'wallpaper',
    imageUrl: 'https://picsum.photos/1080/1920.jpg',
    changeId: 'test-1',
  },
  android: { priority: 'high' },
};

if (mode === 'notif') {
  message.notification = {
    title: 'Prueba',
    body: 'Mensaje recibido con la app cerrada',
  };
}

getMessaging()
  .send(message)
  .then((id) => console.log('Enviado:', id))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });