# Video recommendations

Just a few of the favorite best-practice videos recommended by our contributors.

## Dependency injection: the best pattern

Dependency injection allows code to receive its dependencies from the outside rather than constructing them internally. It is a simple pattern that enables highly configurable and testable software. Recommendations include:

- Inject service-specific implementations behind common interfaces to simplify configuration and reduce branching logic.
- Use factories to construct dependencies based on runtime context; avoid complex conditionals in core request handling code.
- Design systems for testability by injecting mocks and fakes during testing; allow parts of the system to be validated in isolation or in integration.

Watch: [Dependency injection: the best pattern](https://www.youtube.com/watch?v=J1f5b4vcxCQ)

---

## Why I don't use the "else" keyword in my code

Nick explains why he intentionally avoids using the `else` keyword for control flow, because the result is cleaner, more maintainable, and better-structured code. He recommends:

- Eliminate unnecessary nesting by returning early from functions.
- Prefer switch statements and method extraction to clarify control flow.
- Refactor code toward single-responsibility and open/closed design to make additions easier and safer.

Watch: [Why I don't use the "else" keyword in my code](https://www.youtube.com/watch?v=_ougvb8mT7k)

---

## Clean code with horrible performance

Many "clean code" practices, often recommended for maintainability and readability, can drastically harm runtime performance — in some cases by factors of 10x to 20x. Muratori concludes that while maintainability is important, performance should not be sacrificed for dogmatic adherence to clean code rules. He recommends:

- Avoid polymorphism when performance matters.
- Prefer explicit knowledge of data internals when appropriate.
- Be critical of abstract "clean code" prescriptions unless performance trade-offs are clearly understood.

Watch: [Clean code with horrible performance](https://www.youtube.com/watch?v=tD5NrevFtbU)
