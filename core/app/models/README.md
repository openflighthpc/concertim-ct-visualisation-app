# Model Classes

## Introduction

Model classes that are backed by a database are use ActiveRecord.  Any legacy
classes implemented with DataMapper should be converted to ActiveRecord when
being ported.

The model classes have a very long history and have had multiple developers
work on them for almost two decades.  This is resulted in a lot of
inconsistency with them.  Some of this can be improved upon by grouping the
various sections of a model consistently.

## Group methods into sections.

The methods should be grouped in to the following categories in the following
order:

1. ActiveRecord Configuration (e.g., `self.table_name = "devices"`).
2. Constants.
3. Associations.
4. Properties (e.g., `attr_reader :bob ; attr_accessor :kate`).
5. Hooks (e.g., `before_destroy :do_this`).
6. Validations.
7. Delegation.
8. Defaults.
9. Public class methods.
10. Private class methods.
11. Public instance methods.
12. Protected instance methods.
13. Private instance methods.

Each section should be proceeded by a header in the following format.

```


####################################
#
# Associations
#
####################################

has_one :bob
belongs_to :kate
```

If a section is not present for that model there is no requirement for a
section header.

A copy-pastable list of section headers can be found in the
[SECTION_HEADERS.txt](SECTION_HEADERS.txt) file in this directory.
