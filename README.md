# Lizzz - AI Blog Summarization System

A Rails 8 application that collects, processes, and summarizes blog content using AI. The system allows users to:

- **Scrape blog posts** automatically from configured blog sites
- **Add individual article URLs** manually for processing
- **Parse HTML content** and extract clean text using background jobs
- **Generate AI-powered summaries** using OpenAI's API with contextual examples
- **Search similar content** using vector embeddings and similarity matching
- **Organize content by blog site** with nested URL structure

The application combines automated blog scraping with manual content curation, providing intelligent summarization that learns from existing content to maintain consistent tone and style across summaries.

## Key Features

- Background job processing for content parsing and AI summarization
- Vector similarity search for finding related articles
- Review loop system for refined AI-generated summaries
- Clean, responsive UI for managing blog sites and articles
- Status tracking for parsing and summarization progress

## Setup

### Requirements

- Ruby 3.2+
- Rails 8
- PostgreSQL
- OpenAI API key

### Installation

1. Install dependencies:

   ```bash
   bundle install
   ```

2. Setup database:

   ```bash
   rails db:create
   rails db:migrate
   ```

3. Configure environment variables:

   ```bash
   # Create .env file
   OPENAI_API_KEY=your_openai_api_key_here
   ```

4. Start the application:
   ```bash
   rails server
   ```
