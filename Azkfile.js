/**
 * Documentation: http://docs.azk.io/Azkfile.js
 */
// Adds the systems that shape your system
systems({
  rollbax: {
    // Dependent systems
    depends: [],
    // More images:  http://images.azk.io
    image: {"docker": "gullitmiranda/elixir"},
    // Steps to execute before running instances
    provision: [
      "mix do deps.get, compile",
    ],
    workdir: "/azk/#{manifest.dir}",
    shell: "/bin/sh",
    command: "exit 0",
    http: false,
    wait: false,
    mounts: {
      '/azk/#{manifest.dir}': sync("."),
      '/azk/#{manifest.dir}/deps': persistent("./deps"),
      '/azk/#{manifest.dir}/_build': persistent("./_build"),
      '/root/.hex': persistent("#{env.HOME}/.hex"),
    },
    // scalable: { default: 0, limit: 1 },
    envs: {
      // Make sure that the PORT value is the same as the one
      // in ports/http below, and that it's also the same
      // if you're setting it in a .env file
      MIX_ENV: "test",
      TERM   : "linux",
    },
  },
});
