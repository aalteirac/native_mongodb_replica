## Introduction

Test to run MongoDB replica set 3 nodes + Mongo-Express in Snowflake Native App framework

In Snowflake SPCS and Docker in general, there're other ways to manage resilience for a service like MongoDB.
However this test with replica is a good exercise to understand some SNowflake SPCS specificities like network abstraction and service state.

--- NOT FOR PROD ---

Run the content of init.ql on the target account, change the role name if needed

## Demo
[![Demo Video](https://img.youtube.com/vi/M08Af-9V27s/0.jpg)](https://www.youtube.com/watch?v=M08Af-9V27s)

## Prerequisites

1. Snowflake CLI
2. Snowflake Account
3. User with DEMO_ROLE (to be created with init script or modify the snowflake.yml definition)
4. Warehouse DEMO_WH (to be created with init script or modify the snowflake.yml definition)

## Run instructions 

Run:

 ```sh
    snow app run --role DEMO_ROLE
 ```    