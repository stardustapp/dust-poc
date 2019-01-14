module.exports = {
  servers: {
    one: {
      host: 'ec2-52-36-135-46.us-west-2.compute.amazonaws.com',
      username: 'ubuntu',
      pem: '/home/daniel/.ssh/stardust.pem',
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

    dockerImage: 'abernix/meteord:base',
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
