# entra_conditional_access_as_code
This project implements Microsoft Entra Conditional Access policies with Terraform. It parses a list and applies the specified policy configuration. This implementation also extends Terraform's native capability by pushing native json policies to the Microsoft Graph REST endpoint to accomodate new features or issues in the current azurerm provider.
