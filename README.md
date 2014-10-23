
# mm_eager_includer

Eager Include models

## Examples / How-To:


    # in an initializer:
    require 'mongo_mapper/eager_includer'

    # when you want to eager include:
    MongoMapper::EagerIncluder.eager_include(@user, :posts)
    MongoMapper::EagerIncluder.eager_include([@user1, @user2], :posts)
    MongoMapper::EagerIncluder.eager_include(@posts, :user)

## Cleanup hook

  You'll want to run this every so often:

    MongoMapper::EagerIncluder.clear_cache!

  This frees all memory. Do it in an after_filter on ApplicationController (if you are in rails)


## TODO / Bugs:

  * Use the actual association proxy (it would be nicer to say @users.eager_include(:posts))
  * We shouldn't need the cleanup hook.  Is there a better way to free memory (without leaking)?