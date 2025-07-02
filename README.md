# VitaPG

VitaPG is a Ruby on Rails application designed to automate PostgreSQL database backups and securely upload them to various cloud storage services.

## Features

VitaPG offers a robust set of features to manage your PostgreSQL backups:

- **Automated Backups:** Schedule backups to run automatically at your desired frequency using cron expressions.
- **Multiple Database Connections:** Configure and manage backups for several PostgreSQL databases from a single application.
- **Flexible Backup Options:**
    - Exclude specific tables from your backup.
    - Exclude data from specific tables (while still backing up the schema).
    - Option to run `pg_dump` with `--no-owner` and `--no-privileges` flags.
- **Cloud Storage Integration:**
    - Currently supports AWS S3 for storing backup files.
    - Google Drive integration is planned for future releases.
- **Administrative Interface:** Uses [Motor-Admin](https://www.motor-admin.com/) to provide an easy-to-use UI for managing connections, backup routines, and viewing logs.
- **Background Job Processing:** Leverages SolidQueue for reliable execution of backup tasks.
- **Backup Monitoring:** Keep track of backup runs, their status (running, completed, failed), and access logs for troubleshooting.

## Technology Stack

VitaPG technology stack:

- **Backend:** Ruby on Rails
- **Application Database:** SQLite3 (manages application data, no separate server setup needed for this)
- **Target Databases for Backup:** PostgreSQL (the databases you want to back up)
- **Background Jobs:** SolidQueue
- **Admin Interface:** Motor-Admin
- **Cloud Storage:** AWS S3 (initially)
- **Deployment:** Kamal (optional, configured in the project)

## Getting Started

Follow these steps to get VitaPG up and running on your local machine for development or testing:

### Prerequisites

- Ruby (see `.ruby-version` for the exact version)
- Node.js (see `.node-version` for the exact version)
- Yarn
- PostgreSQL server (if you plan to back up PostgreSQL databases)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/vitapg.git
    cd VitaPG
    ```
    
2.  **Install dependencies:**
    ```bash
    bundle install
    yarn install
    ```

3.  **Configure environment variables:**
    Copy the example environment file and customize it with your settings:
    ```bash
    cp .env.example .env
    ```
    Update the `.env` file. This is primarily for services like AWS S3 (access key, secret key, region, bucket for backups). VitaPG itself uses SQLite and does not require database credentials in the `.env` file for its own operation. You will configure credentials for the PostgreSQL databases you intend to back up directly within the application's admin interface.

4.  **Set up the database:**
    This command will create the database, load the schema, and initialize with seed data (if any).
    ```bash
    rails db:setup
    ```

5.  **Start the development server:**
    ```bash
    ./bin/dev
    ```
    This will typically start the Rails server, and you can access VitaPG at `http://localhost:3000`. The Motor-Admin interface will be available at `http://localhost:3000/admin`.

## Usage

Once VitaPG is running, you can manage your backup operations through the Motor-Admin interface:

1.  **Access the Admin Interface:**
    Open your web browser and navigate to `http://localhost:3000/admin` (or your production URL followed by `/admin`). The default credentials are Username = `admin` and Password = `admin`.

2.  **Configure Database Connections:**
    - Go to the "Database Connections" section.
    - Add new connections by providing a name, host, port, database name, username, and password for each PostgreSQL instance you want to back up.

3.  **Set up Destinations:**
    - Go to the "Destinations" section.
    - Add new storage destinations. For AWS S3, you'll need to provide a bucket name, region, access key ID, and secret access key.

4.  **Create Backup Routines:**
    - Go to the "Backup Routines" section.
    - Create a new routine by:
        - Giving it a descriptive name.
        - Selecting the database connection.
        - Selecting the destination.
        - Specifying the backup schedule using a cron expression (e.g., `0 2 * * *` for daily at 2 AM).
        - Configuring any specific `pg_dump` options like tables to exclude, excluding table data, or flags like `--no-owner` and `--no-privileges`.
        - Enabling the routine.

5.  **Monitor Backups:**
    - **Backup Runs:** View the status and history of individual backup attempts in the "Backup Runs" section. Each run will show if it was successful or failed, start/end times, and the URL of the stored backup file if successful.
    - **Backup Logs:** Check "Backup Logs" for detailed information and any errors related to specific backup runs.
    - **Background Jobs:** You can monitor the SolidQueue jobs via the MissionControl interface, typically at `/jobs`.

## Contributing

Contributions are welcome and appreciated! If you'd like to contribute to VitaPG, please follow these general steps:

1.  **Fork the repository.**
2.  **Create a new branch** for your feature or bug fix:
    ```bash
    git checkout -b your-feature-name
    ```
3.  **Make your changes.**
4.  **Add tests** for your changes, if applicable.
5.  **Ensure all tests pass.**
6.  **Commit your changes** with a clear and descriptive commit message.
7.  **Push your branch** to your fork:
    ```bash
    git push origin your-feature-name
    ```
8.  **Submit a pull request** to the main VitaPG repository.

Please ensure your code adheres to the project's coding standards (e.g., by running linters if configured).

## License

This project is released under the **MIT License**.

See the `LICENSE` file in the repository for the full license text. 

## Author

This project was first created by [Bruno Berchielli](https://github.com/bruno-berchielli)
