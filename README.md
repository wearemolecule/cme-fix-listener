![Molecule Software](https://avatars1.githubusercontent.com/u/2736908?v=3&s=100 "Molecule Software")
# CME STP Adapter

[![CircleCI](https://circleci.com/gh/wearemolecule/cme-fix-listener.svg?style=svg)](https://circleci.com/gh/wearemolecule/cme-fix-listener)
[![Docker Repository on Quay](https://quay.io/repository/molecule/cme-fix-listener/status "Docker Repository on Quay")](https://quay.io/repository/molecule/cme-fix-listener)

A service that connects to the [CME's Straight Through Processing API](http://www.cmegroup.com/confluence/display/EPICSANDBOX/CME+STP) to download trades in FIXML format, and returns easy-to-read, JSON-formatted trades.

## Why We Made This
The STP API provides access to trades done on NYMEX, COMEX, DME, CBOT, CME Clearing Europe, CDS and CME. Although the API is fairly easy to use, there are interactions thatare more appriopriately handled independent of the trade creation logic. Those include:
 
 * managing CME downtime, 
 * parsing responses into more desirable formats, and 
 * handling API authentication.
 
This adapter handles these interactions, and lets you focus on handling the trades themselves (which is hard enough!). We think the industry would be better off with a tool like this out in the open, so we open-sourced it.

## To Use

* Set up the prerequisites and the adapter.
* Turn on the adapter.
* Make some trades on ClearPort.
* Pick up your JSON.

## Prerequisites

This service has a few prerequisites.

1. It must be run on a *nix machine.
   * We use Ubuntu.
   * Git, a recent version of [Ruby](https://www.ruby-lang.org/en/), and [bundler](http://bundler.io/) should be installed on the machine.
1. A queue where the adapter can drop JSON-formatted trades.
   * We use [Redis](http://redis.io/); a good hosted Redis is IBM's [Compose.io](https://www.compose.io/redis/).
   * Feel free to adapt this service to work with other message queues, and send us a pull request!
1. A test CME STP account.

## Getting things Running

1. Clone this repo.
1. Run `bundle install`.
1. Set environment variables.
   * You can do this on the machine running the adapter, or in an `application.yml` file. A sample file is in `config/application.sample.yml`.
   * For most things you can leave the defaults.  You will need to set these variables:
      * `RESQUE_HOST` should be the URL of your Redis server, i.e., `redis://x.compose.io:1234`
      * `FETCH_ACCOUNT_FROM_CONFIG` should be set to `true` so that you can configure your CME credentials via config file.
1. Set CME account credentials.
   * You can do this in `config/account-config.json` (recommended), or set up a web service that returns the same information. A sample config file is in `config/account-config-sample.json`.
1. Start the adapter.
   * The listener's entry point is a simple [Thor](http://whatisthor.com/) script. Run `./cme.thor` to start the program (it will begin logging useful information). If you see Creating MasterSupervisor then you know the listener was started correctly.
1. Make a trade on the CME ClearPort website.
1. Look for the FIXML message in the logs, and the JSON in your Redis queue!


## Copyright and License

Copyright © 2016 Molecule Software, Inc. All Rights Reserved.

Licensed under the MIT License (the "License"). You may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE.md file.
