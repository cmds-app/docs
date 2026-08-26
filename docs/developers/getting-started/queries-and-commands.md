# Queries and commands

## Introduction

Queries and commands are a fundamental concept to working with the API.

A **query** is an interrogative to request data. It is expressed as a verb or as a verb-noun phrase. For example:

- Count Answers
- Search Groups

A **command** is an imperative to execute a function. It is expressed as a verb or as a verb-noun phrase. For example:

- Add Question
- Delete
- Join Group
- Send Email

## Queries

The API provides support for several distinct types of query. Here is a summary of the purpose and intended developer use case for each type:

| Query Type | Query Purpose | API Endpoint Template |
| :--- | :--- | :--- |
| **Assert** | Check for the existence of one specific item in a collection using a key value (returns true or false) | **HEAD** `api/collection/{id}` |
| **Collect** | Collect the list of items that match specific criteria in a collection (returns a paged list of heavyweight models, suitable for a detailed view of each item in a user interface; also suitable for integration with other systems) | **POST** (or GET) `api/collection/collect` |
| **Count** | Count the list of items that match specific criteria in a collection (returns an integer) | **POST** (or GET) `api/collection/count` |
| **Download** | Download the list of items that match specific criteria in a collection (returns an unpaged list of heavyweight models, suitable for a detailed view of each item in a user interface; also suitable for integration with other systems) | **POST** (or GET) `api/collection/download` |
| **Export** | Export the list of items that match specific criteria in a collection (returns a private and secure link to download the export file; link expires after 1 hour) | **POST** `api/collection/export` |
| **Retrieve** | Retrieve one specific item in a collection using a key value (returns a heavyweight model suitable for a detailed view of the item in a user interface) | **GET** `api/collection/{id}` |
| **Search** | Search for the list of items that match specific criteria in a collection (returns a paged list of lightweight models intended for search results, combo boxes, lookups, etc.) | **POST** (or GET) `api/collection/search` |
