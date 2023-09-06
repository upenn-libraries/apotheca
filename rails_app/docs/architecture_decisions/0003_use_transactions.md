# 1. Use Transactions
   Date: 2022-11-08

   Status: `Accepted`

# 2. Context

    When creating or changing Valkyrie Resources there are tasks that need to be run before/after those operations. For example, creating an ARK and generating derivatives.

# 3. Decision

    To wrap tasks that need to happen around the creation, update and removal of Valkyrie Resources, we have decided to use [dry-transactions](https://github.com/dry-rb/dry-transaction). This library will provide us the flexibility to share code between transactions and provide an interface to implement a readable sequence of steps. If necessary we can also pass additional attributes to each step. 

# 4. Consequences

    1. Transactions must be used! 
        a. Any changes that happen to a Resources must go through a Transaction so that the appropriate callbacks are called. There is nothing preventing the resources from being altered or created directly. This means we have to consistently use transactions everywhere in our code.
    2. Sequencial steps
        a. Transactions are defined by a set of linear steps and each step gets all the attributes needed from the step prior. Therefore if a flag is needed for the 10th step all the steps prior to it will have to continue passing on that flag.
        b. There also isn't a very readable API for defining when steps can be skipped. The step itself needs to decide whether a step should be run on not. Callbacks in ActiveRecord allow for shorthands that can be used to selectively run a callback.
    3. Sharing code between bulk import and UI code
        a. By using transactions it will be easy to share code that creates, update and removes Resources between the bulk import and controllers. 
    4. Adding additional steps 
        a. There will be a clear place to add additional steps when needed.
