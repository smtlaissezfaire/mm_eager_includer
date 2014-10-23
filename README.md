
# mm_eager_include

Eager Include models

## Examples:

    MongoMapper::EagerIncluder.eager_include(@user, :posts)
    MongoMapper::EagerIncluder.eager_include([@user1, @user2], :posts)
    MongoMapper::EagerIncluder.eager_include(@posts, :user)

## Cleanup hook

  You'll want to run this every so often:

    MongoMapper::EagerIncluder.clear_cache!

  This frees all memory. Do it in an after_filter on ApplicationController (if you are in rails)
