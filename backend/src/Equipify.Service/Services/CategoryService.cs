using Equipify.Data.Repositories;
using Equipify.Domain.Entities;
using Equipify.Service.Models;
using Equipify.Service.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Equipify.Service.Services;

public class CategoryService : ICategoryService
{
    private readonly IUnitOfWork _uow;

    public CategoryService(IUnitOfWork uow) => _uow = uow;

    public Task<List<Category>> GetAllAsync()
        => _uow.Categories.Query().Include(c => c.Listings).OrderBy(c => c.Name).ToListAsync();

    public Task<Category?> GetByIdAsync(int id) => _uow.Categories.GetByIdAsync(id);

    public async Task<ServiceResult<int>> CreateAsync(string name, string? picturePath)
    {
        if (string.IsNullOrWhiteSpace(name))
            return ServiceResult<int>.Fail("Category name is required.");
        if (await _uow.Categories.AnyAsync(c => c.Name == name.Trim()))
            return ServiceResult<int>.Fail("A category with this name already exists.");

        var category = new Category { Name = name.Trim(), Picture = picturePath };
        await _uow.Categories.AddAsync(category);
        await _uow.SaveChangesAsync();
        return ServiceResult<int>.Ok(category.Id);
    }

    public async Task<ServiceResult> UpdateAsync(int id, string name, string? picturePath)
    {
        var category = await _uow.Categories.GetByIdAsync(id);
        if (category is null) return ServiceResult.Fail("Category not found.");
        if (string.IsNullOrWhiteSpace(name))
            return ServiceResult.Fail("Category name is required.");

        category.Name = name.Trim();
        if (!string.IsNullOrWhiteSpace(picturePath))
            category.Picture = picturePath;

        _uow.Categories.Update(category);
        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }

    public async Task<ServiceResult> DeleteAsync(int id)
    {
        var category = await _uow.Categories.GetByIdAsync(id);
        if (category is null) return ServiceResult.Fail("Category not found.");
        if (await _uow.Listings.AnyAsync(l => l.CategoryId == id))
            return ServiceResult.Fail("Cannot delete a category that still has listings.");

        _uow.Categories.Remove(category);
        await _uow.SaveChangesAsync();
        return ServiceResult.Ok();
    }
}
