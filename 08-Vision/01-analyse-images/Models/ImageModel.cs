using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace ImageWebApp.Models
{
    public class ImageModel
    {
        [Required]
        [Display(Name = "Select an image file")]
        public IFormFile? ImageFile { get; set; } // This property will store the uploaded image file
        public string? InputText { get; set; } // This property will store the uploaded image file
    }
}
