// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { createConsumer } from "@rails/actioncable"
import "kanban_board"
import "expense_components"
import "dropping_text"
import "alex_chat"

window.cable = createConsumer()
