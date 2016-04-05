
# mm_eager_includer

Eager Include models

## Examples / How-To:

    # in an initializer:
    require 'mongo_mapper/eager_includer'

    # when you want to eager include:
    MongoMapper::EagerIncluder.eager_include(@user, :posts)
    MongoMapper::EagerIncluder.eager_include([@user1, @user2], :posts)
    MongoMapper::EagerIncluder.eager_include(@posts, :user)


## TODO / Bugs:

  * Use the actual association proxy (it would be nicer to say @users.eager_include(:posts))
