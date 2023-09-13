# Use Transactions
   
## Date
2022-11-08

## Status
`Accepted`

## Context
When creating or changing Valkyrie Resources there are tasks that need to be run before/after those operations. For example, creating an ARK and generating derivatives.

## Decision
To wrap tasks that need to happen around the creation, update and removal of Valkyrie Resources, we have decided to use [dry-transactions](https://github.com/dry-rb/dry-transaction). This library will provide us the flexibility to share code between transactions and provide an interface to implement a clearly delineated  sequence of steps. If necessary, we can also pass additional attributes to each step. We were inspired by Hyrax's use of transactions.

## Consequences
1. Transactions must be used! 
   * Any changes that happen to a Resource must go through a Transaction so that the appropriate callbacks are run. There is nothing preventing the Resources from being altered or created directly. This means we have to consistently use transactions everywhere in our code.
2. Sequential steps
   * Transactions are defined by a set of linear steps and each step gets all the attributes needed from the step prior. Therefore, if a flag is needed for the 10th step all the steps prior to it will have to continue passing on that flag.
   * There also isn't a very readable API for defining when steps can be skipped. The step itself needs to decide whether a step should be run on not. Callbacks in ActiveRecord allow for shorthands that can be used to selectively run a callback.
3. Sharing code between bulk import and UI code
   * By using transactions it will be easy to share code that creates, update and removes Resources between the bulk import code and controllers. 
4. Adding additional steps 
   * There will be a clear place to add additional steps when needed.
