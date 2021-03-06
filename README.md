# snare
## ( site - node - attribute - relationship - entity )

Snare is a simple JSON API intended for semantic wikis and various experiments in playing with data. It is a spiritual successor to brainiac with some inspiration taken from the Everything2 writing community and ENQUIRE by Tim Berners-Lee.

Snare is intended to encourage a simple way for semantic wikis to refer to specific sections of writing across servers, while acting as a simple backend for programmers to mess with data that is shared in this way.

The code and description that's up now is largely a rough sketch of what I had in mind. It's nowhere near complete at this point, but github makes version control easy peasy lemon squeezy.

Snare is written in Ruby using Sinatra, and uses Redis as a database.

Snare consists of a few simple objects:

### Site

Sites hold collections of nodes, attributes, relationships and entities.

### Nodes

Nodes hold entries of writing classified under a specific concept defined as the node's title. Entries may explicitly link to any other objects or entities of their choosing.

### Relationships

Relationships outline the connections nodes hold with one another. For example: If I had a node representing "ATL" and another one called the "The Dirty South", I can specify a relationship that specifies

ATL -> "torchbearer of" -> The Dirty South

Any time that either "The Dirty South" or "ATL" arte queried for adjacent relationships, it's shown that ATL is the torchbearer of the crunk scene that is the Dirty South.

Relationships may also exist between nodes and entities, or even between entities.

### Entities

Entities are references to external links, media, or other snare objects that exist across sites. Any entities that are defined as snare objects may be treated similarly to nodes that are local to a site. Editing such entities as snare entries merely saves the changes locally, with the option to publicly display such modified entries.

### Functionality

* Sites
* Nodes
* Attributes
* Relationships
* Tagging
* JSON output

### Roadmap

* Entities
* RDF output
* External Snare entity querying
* User/Client Authentication
* Example Client
* SPARQL querying of snare objects

### Potential Features

* External Entity Caching (referenced media, snare entries)
* Entry Version Control
