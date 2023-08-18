###################################################################################
#SQLServer Support
#ODBC
#https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16&tabs=debian18-install%2Cdebian17-install%2Cdebian8-install%2Credhat7-13-install%2Crhel7-offline
#sudo su


curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

#Download appropriate package for the OS version
#Debian 11
sudo chmod +777 /etc/apt/sources.list.d/mssql-release.list
curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list

apt-get update

sudo ACCEPT_EULA=Y apt-get install -y msodbcsql17
# optional: for bcp and sqlcmd
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools
echo "" | sudo tee -a /etc/profile #.profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' | sudo tee -a /etc/profile #.profile
#sudo echo 'export PATH="$PATH:/opt/microsoft/msodbcsql17/share/resources/en_US/msodbcsqlr17.rll"' >> /etc/profile
# optional: for unixODBC development headers
sudo apt-get install -y unixodbc-dev
# optional: kerberos library for debian-slim distributions
sudo apt-get install -y libgssapi-krb5-2
########################################################################################





