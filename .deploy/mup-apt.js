module.exports = {
  servers: {
    apartment: {
      host: 'dan-lenovo',
      username: 'stardust',
      pem: '/home/daniel/.ssh/stardust.pem',
    },
  },

  meteor: {
    name: 'stardust',
    path: '..',
    servers: {
      apartment: {},
    },
    buildOptions: {
      serverOnly: true,
    },
    env: {
      ROOT_URL: 'http://apt.danopia.net',
      MONGO_URL: 'mongodb://localhost/meteor'
    },

    dockerImage: 'abernix/meteord:base',
    deployCheckWaitTime: 60
  },

  mongo: {
    oplog: true,
    port: 27017,
    servers: {
      apartment: {},
    },
  },
};
