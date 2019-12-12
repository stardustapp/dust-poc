module.exports = {
  servers: {
    one: {
      host: '10.69.1.12',
      username: 'ubuntu',
      pem: '/home/dan/.ssh/stardust.pem',
    },
  },

  meteor: {
    name: 'stardust',
    path: '..',
    servers: {
      one: {},
    },
    buildOptions: {
      serverOnly: true,
    },
    env: {
      ROOT_URL: 'https://withstardust.tech',
      MONGO_URL: 'mongodb://localhost/meteor'
    },

    dockerImage: 'abernix/meteord:node-8.15.1-base',
    deployCheckWaitTime: 60
  },

  mongo: {
    oplog: true,
    port: 27017,
    servers: {
      one: {},
    },
  },
};
