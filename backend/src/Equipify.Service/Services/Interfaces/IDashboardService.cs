using Equipify.Service.Models;

namespace Equipify.Service.Services.Interfaces;

public interface IDashboardService
{
    Task<DashboardStats> GetStatsAsync();
}
