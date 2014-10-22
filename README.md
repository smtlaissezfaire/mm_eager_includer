
# mm_eager_include

Eager Include models

## Examples:

    MongoMapper::EagerIncluder.eager_include(@user, :posts)
    MongoMapper::EagerIncluder.eager_include([@user1, @user2], :posts)
    MongoMapper::EagerIncluder.eager_include(@posts, :user)

