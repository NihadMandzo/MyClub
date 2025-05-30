using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using MyClub.Model.Responses;
using System;
using System.Linq;
using System.Net;

namespace MyClub.WebAPI.Filters
{
    public class ErrorFilter : IExceptionFilter
    {
        public void OnException(ExceptionContext context)
        {
            if (context.Exception is UserException)
            {
                UserException exception = (UserException)context.Exception;
                context.ModelState.AddModelError("ERROR", exception.Message);
                context.HttpContext.Response.StatusCode = exception.StatusCode;
            }
            else
            {
                context.ModelState.AddModelError("ERROR", "Internal server error");
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            }

            var list = context.ModelState.Where(x => x.Value.Errors.Count > 0).ToDictionary(x => x.Key, y => y.Value.Errors.Select(z => z.ErrorMessage));

            context.Result = new JsonResult(new { errors = list });
        }
    }
}