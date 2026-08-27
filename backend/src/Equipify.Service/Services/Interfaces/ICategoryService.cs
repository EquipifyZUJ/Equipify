using Equipify.Domain.Entities;
using Equipify.Service.Models;

namespace Equipify.Service.Services.Interfaces;

public interface ICategoryService
{
    Task<List<Category>> GetAllAsync();
    Task<Category?> GetByIdAsync(int id);
    Task<ServiceResult<int>> CreateAsync(string name, string? picturePath);
    Task<ServiceResult> UpdateAsync(int id, string name, string? picturePath);
    Task<ServiceResult> DeleteAsync(int id);
}
