# WulinAudit

## How to Use

1. WulinAudit is depends on mongoDB database, before use it you need install mongodb.

   On Mac OS X using Homebrew:

     ```shell
     brew install mongodb
     ```

   On Ubuntu & Debian:
   please read the installation from mongoDB Official Website : {Ubuntu and Debian packages}[www.mongodb.org/display/DOCS/Ubuntu+and+Debian+packages].

2. Put `gem wulin_audit` to your Gemfile:

    ```ruby
    gem wulin_audit
    ```

3. Run bundler command to install the gem:

    ```shell
    bundle install
    ```

4. Now, you have **_WulinAudit::AuditLogsController_** and **_WulinAudit::AuditLog_** model, and it will audit all the models automatically.

   Attributes in `WulinAudit::AuditLog`:

    ```ruby
    user_id    # current user's id, equal to +User.current_user.try(:id)+
    user_email # current user's email, equal to +User.current_user.try(:email)+
    record_id  # id for record which was audited.
    action     # current action name
    class_name # class name for record which was audited
    detail     # changes detail.
    ```

   WulinAudit will audit all the models automatically;
   if you do not want audit some, use +reject_audit+ method:

    ```ruby
    class Post < ActiveRecord::Base
      reject_audit
    end
    ```

   the `Post` model will skip audit.

   If a module was audited, WulinAudit will audit all the columns automatically,
   You also can control which columns need audit, you need use `audit_columns` method:

    ```ruby
    class Post < ActiveRecord::Base
      audit_columns(%w(title content category) & column_names)
      audit_columns :title, :content, :category
      audit_columns 'title', 'content', 'category'
    end
    ```

   Note that, `audit_columns` will be ignored when audit be rejected by +reject_audit+ method

## Work with WulinMaster

**_[WulinMaster](https://github.com/wulin/wulin_master)_** is a grid gem base on [SlickGrid](https://github.com/mleibman/SlickGrid).
It provide powerfull generator and other tools to make grids easy to build.
WulinAudit support WulinMaster well. if you use WulinMaster gem,it will support it automatically.

## Contributing

Jimmy, Xuhao and Maxime Guilbot from Ekohe, inc.

## License

WulinOAuth is released under the MIT license.
