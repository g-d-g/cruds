    
This Module provides functions to 
create, update, delete and get entities
from mongodb.

The module also support REST and websocket
interfaces for crud.

To use the module just do require("crud")( mongo connection string )

    module.exports = (mongoDbConnectionString) ->
    
        MongoClient = require('mongodb').MongoClient
        ObjectID = require('mongodb').ObjectID

Functions to return will be created in the 'ex' variable
    
        ex = {}

Connect to the mongodb instance with the help of the connect
function. This function will cache the connection
and will not open new connections even if called multiple
times.

        mdb = null
        listeners = []
        connect = (callBack) ->
            if mdb is not null
                callBack mdb
                return
            else
                listeners.push callBack

            mongoDbConnectionString = "mongodb://localhost:27017/Entity" if not mongoDbConnectionString
            MongoClient.connect mongoDbConnectionString,  { native_parser:true, auto_reconnect: true }, (err, db) ->
                if !err
                    mdb = db
                for listener in listeners
                    listener mdb

Create an entity

The function takes the following arguments
entityName - string 
entityValue - entity object
callBack - function

        ex.create = (entityName, entityValue, callBack) ->

            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        col.save entityValue, callBack
                    else
                        callBack err, col

Update an entity
 
The function takes the following arguments:  
entityName - string  
entityValue - entity object  
callBack - function  

        ex.update = (entityName, entityId, entityValue, callBack) ->
            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        delete entityValue._id
                        col.update {"_id": new ObjectID(entityId)}, entityValue, {upsert: true}, (err, item) ->
                            callBack err, item
                    else
                        callBack err, col

Query entities
 
entityName - string  
query - mongodb query  
callBack - function

        ex.get = (entityName, query, callBack) ->
            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        col.find query, (err, cursor) ->
                            if !err
                                cursor.toArray (err, items) ->
                                    callBack err, items
                            else
                                callBack err, cursor
                    else
                        callBack err, col

GET single item with the help of this function

        ex.getById = (entityName, id, callBack) ->
            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        col.findOne {"_id": new ObjectID(id)}, (err, item) ->
                            if !item
                                callBack err, {}
                            else
                                callBack err, item
                    else
                        callBack err, col

Delete Entity with id
    
        ex.delete = (entityName, id, callBack) ->
            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        col.remove {"_id": new ObjectID(id)}, (err) ->
                            callBack err
                    else
                        callBack err, col


The following module.export returns and app
that provides the REST interface for an Entity

        ex.getApp = (name) ->
            express = require('express')
            app = express()
          
            getQuery = (requestQuery) ->
            
                query = {}

                for key, value of requestQuery
                    if !isNaN(Number value)
                        query[key] = Number value
                    else if key is '_id'
                        query[key] = ObjectID value
                    else
                        query[key] = value
            
                return query
      
Query items from root url
by sending query parameters
in the get request

            app.get '/', (req, res) ->
          
                query = getQuery req.query
        
                ex.get name, query, (err, items) ->
                    if err
                        res.send 400, "something went wrong"
                    else
                        res.send items
      
Get a single item by sending GET 
request to root url

            app.get '/:id', (req, res) ->

                ex.getId name, req.param('id'), (err, item) ->
                    if !err
                        res.send item
                    else
                        res.send 400, 'Something went wrong!'
              
Post to root to create one entity
the JSON object of the entity is 
sent in request body

            app.post '/', (req, res) ->

                ex.create name, req.body, (err, item) ->
                    if !err
                        res.send item
                    else 
                        res.send 400, 'Something went wrong!'
    
Delete item by sending http delete
to the entity uri

            app.delete '/:id', (req, res) ->

                ex.delete name, req.param('id'), (err) ->
                    if !err
                        res.send {}
                    else
                        res.send 400, "Something went wrong!"
    
To update send the new values in
request body to the entity url

            app.put '/:id', (req, res) ->

                ex.update name, req.param('id'), req.body, (err, item) ->
                    if !err
                        res.send item
                    else 
                        res.send 400, 'Something went wrong!'
        
            app

        ex

  
