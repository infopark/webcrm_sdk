This projects uses [appraisal](https://github.com/thoughtbot/appraisal) to test with multiple Rails versions.

The `Appraisals` file in the basedir of the project defines the gems to load in addition to the gems defined in the `Gemfile`.

To regenerate the `Appraisals` file, run:

```sh
bundle exec appraisal install
```

To run tests using one of the generated gemfiles:

```sh
bundle exec appraisal rails-4 rake spec
bundle exec appraisal rails-5 rake spec
```
