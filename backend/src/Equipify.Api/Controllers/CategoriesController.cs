using Equipify.Api.Contracts;
using Equipify.Api.Infrastructure;
using Equipify.Service.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Equipify.Api.Controllers;

[ApiController]
[Route("api/categories")]
public class CategoriesController : ControllerBase
{
    private readonly ICategoryService _categories;

    public CategoriesController(ICategoryService categories) => _categories = categories;

    /// <summary>All categories (public).</summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<List<CategoryDto>>> GetAll()
        => Ok((await _categories.GetAllAsync()).Select(CategoryDto.From).ToList());

    /// <summary>A single category (public).</summary>
    [HttpGet("{id:int}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById(int id)
    {
        var category = await _categories.GetByIdAsync(id);
        return category is null ? NotFound() : Ok(CategoryDto.From(category));
    }
}
