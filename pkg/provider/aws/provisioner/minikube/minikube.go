package minikube

import (
	"fmt"
	"log"
	"time"

	"github.com/shalb/cluster.dev/pkg/cluster"
	"github.com/shalb/cluster.dev/pkg/provider/aws"
	"github.com/shalb/cluster.dev/pkg/provider/aws/provisioner"
	awsProvisioner "github.com/shalb/cluster.dev/pkg/provider/aws/provisioner"
)

// Minikube class.
type Minikube struct {
	providerConf   aws.Config
	minikubeModule aws.Operation
	state          *cluster.State
}

func init() {
	err := aws.RegisterProvisionerFactory("minikube", &Factory{})
	if err != nil {
		log.Fatalf("can't register aws minikube provisioner")
	}
}

// Factory create new aws minikube provisioner.
type Factory struct{}

// New create new instance of EKS provisioner.
func (f *Factory) New(providerConf aws.Config, state *cluster.State) (aws.Operation, error) {
	provisioner := &Minikube{}
	provisioner.providerConf = providerConf
	minikubeFactory, exists := aws.GetModulesFactories()["minikube"]
	if !exists {
		return nil, fmt.Errorf("module 'minikube', needed by provisioner is not found")
	}
	var err error
	provisioner.minikubeModule, err = minikubeFactory.New(providerConf, state)
	provisioner.state = state
	if err != nil {
		return nil, err
	}
	return provisioner, nil
}

// Deploy EKS provisioner modules, save kubernetes config to kubeConfig string.
// Upload kube config to s3.
func (p *Minikube) Deploy() error {
	err := p.minikubeModule.Deploy()
	if err != nil {
		return err
	}

	p.state.KubeConfig, err = awsProvisioner.PullKubeConfig(p.providerConf.ClusterName, 10*time.Minute)
	if err != nil {
		return err
	}

	return provisioner.CheckKubeAccess(p.state.KubeConfig)
}

// Destroy minikube provisioner objects.
func (p *Minikube) Destroy() error {
	err := p.minikubeModule.Destroy()
	if err != nil {
		return err
	}
	p.state.KubeConfig = []byte{}
	return nil
}

// Check - if s3 bucket exists.
func (p *Minikube) Check() (bool, error) {
	return true, nil
}

// Path - return module path.
func (p *Minikube) Path() string {
	return ""
}

// Clear - remove tmp and cache files.
func (p *Minikube) Clear() error {
	return p.minikubeModule.Clear()
}
