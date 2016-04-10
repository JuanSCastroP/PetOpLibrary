//
//  ViewController.swift
//  petOpLibrary
//
//  Created by mac on 4/9/16.
//  Copyright © 2016 Juan Sebastian Castro. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet weak var capturaISBN: UITextField!
    //@IBOutlet weak var devuelveLibro: UITextView!
    @IBOutlet weak var devuelveTitulo: UITextView!
    @IBOutlet weak var devuelveAutor: UITextView!
    @IBOutlet weak var devuelvePortada: UIImageView!
    
    var ISBN = 0
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func Buscar(){
    
        var urls = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:"
        
        urls += capturaISBN.text! // concatena la URL con el ISBN que se ingrese
        
        let url = NSURL (string: urls) //convierte a URL la direccion del servidor
        let datos : NSData? = NSData(contentsOfURL: url!) // hace peticion al servidor
        
        if datos  != nil {
            
            let texto = NSString(data:datos!, encoding:NSUTF8StringEncoding) //codifica a UTF8
            //print(texto!)
            
            if texto == "{}"{
                devuelveTitulo.text = "ISBN No Encontrado"
                showErrorAlertMessage(devuelveTitulo.text)
                
            }else{
                //var tempTexto = texto as! String // convierte el NSString en string
                //devuelveLibro.text = tempTexto //evia a uitextview el texto
                do
                {
                    let json = try NSJSONSerialization.JSONObjectWithData(datos!, options: NSJSONReadingOptions.MutableLeaves)
                    let codISBN = "ISBN:" + self.capturaISBN.text!
                    let dico1 = json as! NSDictionary
                    let dico2 = dico1[codISBN] as! NSDictionary
                    let title = dico2["title"] as! NSString as String
                    
                    let authors = dico2["authors"] as? [[String: AnyObject]]
                    
                    var autores: String = ""
                    for autor  in authors!
                    {
                        if let name = autor["name"] as? String
                        {
                            // Do stuff with data
                            if ( autores != "" )
                            {
                                autores = autores + ","
                            }
                            autores = autores + (name)
                        }
                    }
                    
                    if let portada1 = dico2["cover"]
                    {
                        let portadas = portada1 as! NSDictionary
                        let portada = portadas["medium"] as! NSString as String
                        if let checkedUrl = NSURL(string: portada) {
                            self.devuelvePortada.contentMode = .ScaleAspectFit
                            //self.downloadImage(checkedUrl)
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        // code here
                        //self.resultsTextView.text = (texto as! String)
                        self.devuelveTitulo.text = title
                        self.devuelveAutor.text = autores
                    })
                    
                }//llave do
                catch _{
                }
                
                
                
            }
            
            
            
        }else{
            devuelveTitulo.text = "Verifique su conexion a Internet"
            showErrorAlertMessage(devuelveTitulo.text)
        }
        
    
    }
    
    @IBAction func BuscarButton(sender: AnyObject) {
            Buscar()
       
    }
    
    private func showErrorAlertMessage(mensaje: String) {
        let alertController = UIAlertController(title: "Error", message: mensaje, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
        //clearFields()
    }
    

    @IBAction func limpiarISBN(sender: AnyObject) {
        capturaISBN.text = ""
        devuelveTitulo.text = ""
        devuelveAutor.text = ""
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
