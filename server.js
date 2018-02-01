// Setup
var express = require('express');
var app = express();                                              // create our app w/ express
var mongoose = require('mongoose');                               // mongoose for mongodb
var port = process.env.BACKEND_PORT || process.env.PORT || 3000;  // set the port from envs, fallback to 3000
var database = require('./config/database');                      // load the database config
var paths = require('./config/paths');                            // load the path config
var morgan = require('morgan');
var bodyParser = require('body-parser');
var methodOverride = require('method-override');

// Configuration
mongoose.connect(database.remoteUrl);                         // connect to local MongoDB instance. A remoteUrl is also available (modulus.io)
app.use(express.static(paths.staticFiles));                   // set the static files location /public/img will be /img for users
app.use(morgan('dev'));                                       // log every request to the console
app.use(bodyParser.urlencoded({'extended': 'true'}));         // parse application/x-www-form-urlencoded
app.use(bodyParser.json());                                   // parse application/json
app.use(bodyParser.json({type: 'application/vnd.api+json'})); // parse application/vnd.api+json as json
app.use(methodOverride('X-HTTP-Method-Override'));            // override with the X-HTTP-Method-Override header in the request

// Routes
require('./app/routes.js')(app);

// Start listening
app.listen(port);
console.log("App listening on port " + port);
