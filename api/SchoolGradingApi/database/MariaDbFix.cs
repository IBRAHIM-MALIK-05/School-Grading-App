using System.Data.Common;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace SchoolGradingApi.database
{
    // WHY THIS FILE EXISTS
    // Before Update-Database changes anything, EF Core "locks" the database with:
    //     SELECT GET_LOCK('__EFMigrationsLock',-1);      (-1 = wait forever)
    // This works on MySQL 8 (Azure), but XAMPP's MariaDB 10.4 behaves differently:
    //   1) it answers -1 with NULL instead of 1, and
    //   2) it sends the answer as a 32-bit int, while the provider expects a 64-bit long.
    // Both make the MySQL provider crash, so Update-Database fails on XAMPP.
    //
    // An "interceptor" is an official EF Core hook that runs just before a SQL
    // command is sent (…Executing) and just after the answer comes back (…Executed).
    // This one touches ONLY the migration-lock commands:
    //   - before: use a long positive wait (1 year) instead of -1
    //   - after:  turn MariaDB's int answer into a long
    // Every other query is left unchanged. Registered in Program.cs.
    public class MariaDbFix : DbCommandInterceptor
    {
        private static bool IsMigrationLock(DbCommand command)
        {
            return command.CommandText.Contains("__EFMigrationsLock");
        }

        // BEFORE the command is sent
        public override InterceptionResult<object> ScalarExecuting(
            DbCommand command, CommandEventData eventData, InterceptionResult<object> result)
        {
            if (IsMigrationLock(command))
            {
                command.CommandText = Regex.Replace(
                    command.CommandText,
                    @"GET_LOCK\('__EFMigrationsLock',\s*-1\)",
                    "GET_LOCK('__EFMigrationsLock', 31536000)");
            }
            return result;
        }

        // AFTER the answer comes back
        public override object? ScalarExecuted(
            DbCommand command, CommandExecutedEventData eventData, object? result)
        {
            if (IsMigrationLock(command) && result is int number)
            {
                return (long)number;
            }
            return result;
        }

        // Same two steps for the async versions
        public override ValueTask<InterceptionResult<object>> ScalarExecutingAsync(
            DbCommand command, CommandEventData eventData, InterceptionResult<object> result,
            CancellationToken cancellationToken = default)
        {
            return ValueTask.FromResult(ScalarExecuting(command, eventData, result));
        }

        public override ValueTask<object?> ScalarExecutedAsync(
            DbCommand command, CommandExecutedEventData eventData, object? result,
            CancellationToken cancellationToken = default)
        {
            return ValueTask.FromResult(ScalarExecuted(command, eventData, result));
        }
    }
}
